class Contact
  attr_accessor :content, :id, :title, :name, :xml, :updated, :external_id, :user, :marked_for_deletion, :etag

  def initialize(content_or_id, connection, user)
    @user = user
    @connection = connection
    @content = {}
    @content[:emails] = []
    @content[:ims] = []
    @content[:phone_numbers] = []
    @content[:addresses] = []
    if content_or_id.is_a?(Nokogiri::XML::Element)
      read(content_or_id)
    elsif content_or_id.is_a?(String)
      retrieve(content_or_id)
    elsif content_or_id.is_a?(Array)
      content_or_id
    end
  end
  
  def print_time(date_time)
    date = date_time.to_date
    time = date_time.to_time
    date.strftime("%D") + ' ' + time.getlocal.strftime("%I:%M:%S %p")
  end
  
  def deleted?
    @marked_for_deletion ? 'DELETED' : nil
  end
  
  def to_s
    full_name = @name ? @name.full_name : ''
    [full_name, print_time(@updated), deleted?].compact.join(' - ')
  end
  alias :inspect :to_s

  def create_or_update_for(user)
    if user.contact_ids.include?(@external_id.id_value)
      contact_id = user.contacts[@external_id.id_value].id
      user.connection.put(user.url + '/full/' + contact_id, write(user.group_id))
    else
      user.connection.post(user.url + '/full', write(user.group_id))
    end
  end
  
  def create_for(user)
    user.connection.post(user.url + '/full', write(user.group_id))
  end
  
  def update_for(user, time = nil)
    contact_id = user.contacts[@external_id.id_value].id
    user.connection.put(user.url + '/full/' + contact_id, write(user.group_id, time))
  end
  
  def delete_for(user)
    contact_id = user.contacts[@external_id.id_value].id
    
    builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      xml.entry(xmlns: 'http://www.w3.org/2005/Atom', 'xmlns:gContact' => 'http://schemas.google.com/contact/2008', 'xmlns:batch' => 'http://schemas.google.com/gdata/batch', 'xmlns:gd' => 'http://schemas.google.com/g/2005', 'gd:etag' => '*') do
        xml.category(
          scheme: "http://schemas.google.com/g/2005#kind",
          term: "http://schemas.google.com/contact/2008#contact"
        )
        xml.id_ "https://www.google.com/m8/feeds/contacts/default/base/#{@id}" if @id
      end
    end
    xml = builder.to_xml
    
    user.connection.headers['If-match'] = '*'
    user.connection.delete(user.url + '/full/' + contact_id)
  end

  def values
    members = []
    @content.each do |type, values|
      members << values unless values.empty?
    end
    members << @external_id
    members.flatten
  end

  # def create(group_id = nil)
  #   contact_array = [%{<atom:entry xmlns:atom='http://www.w3.org/2005/Atom'
  #       xmlns:gd='http://schemas.google.com/g/2005'>
  #     <atom:category scheme='http://schemas.google.com/g/2005#kind'
  #       term='http://schemas.google.com/contact/2008#contact'/>}]
  # 
  #   @content.each do |name, element|
  #     if element.is_a?(Array)
  #       element.each do |member|
  #         contact_array << member.write
  #       end
  #     else
  #       contact_array << element.write
  #     end
  #   end
  # 
  #   contact_array << "</atom:entry>"
  # 
  #   contact_array.join(' ')
  # end
  
  def newer_than?(other_contact)
    @updated > other_contact.updated
  end

  def update(group_id = nil)
    @connection.put('https://www.google.com/m8/feeds/contacts/default/full/' + @id, write(@user.group_id))
  end

  def read(xml)
    @etag = xml.attribute('etag').value
    xml.children.each do |node|
      case node.name
      when 'externalId'
        @external_id = ExternalId.new(node)
      when 'updated'
        time = node.content.split('.').first + 'UTC'
        @updated = DateTime.strptime(time, "%Y-%m-%dT%T%Z")
      when 'id'
        @id = node.content.split('/').last
      when 'title'
        @title = node.content
      when 'name'
        @name = Name.new(node)
      when 'email'
        @content[:emails] << Email.new(node)
      when 'im'
        @content[:ims] << Im.new(node)
      when 'phoneNumber'
        @content[:phone_numbers] << PhoneNumber.new(node)
      when 'structuredPostalAddress'
        @content[:addresses] << Address.new(node)
      end
    end

    unless @external_id
      generate_external_id
      update
    end

    @content
  end

  def generate_external_id
    ext_id = []
    if @name
      ext_id << [@name.first_name[:value], @name.last_name[:value]]
    elsif !@content[:emails].empty?
      ext_id << @content[:emails][0]
    end  
    ext_id << Time.now.strftime("%Y%m%d%H%M")
    
    ext_id = ext_id.flatten.compact.join.downcase
    @external_id = ExternalId.new(ext_id)
  end
  
  def create_or_update(xml, group_id)
    xml.category(
      scheme: "http://schemas.google.com/g/2005#kind",
      term: "http://schemas.google.com/contact/2008#contact"
    )
    xml.id_ "https://www.google.com/m8/feeds/contacts/default/base/#{@id}" if @id
    xml.title_ @title
    if @name
      xml.send(@name.tag) do
        @name.write(xml)
      end
    end
    values.each do |element|
      xml.send(element.tag, element.attribute_hash, element.value) do
        element.write(xml)
      end
    end
    xml.send('gContact:groupMembershipInfo', :deleted => 'false', :href => group_id)
  end

  def write(group_id, time = nil)
    builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      xml.entry(xmlns: 'http://www.w3.org/2005/Atom', 'xmlns:gContact' => 'http://schemas.google.com/contact/2008', 'xmlns:batch' => 'http://schemas.google.com/gdata/batch', 'xmlns:gd' => 'http://schemas.google.com/g/2005', 'gd:etag' => '*') do
        xml.category(
          scheme: "http://schemas.google.com/g/2005#kind",
          term: "http://schemas.google.com/contact/2008#contact"
        )
        xml.id_ "https://www.google.com/m8/feeds/contacts/default/base/#{@id}" if @id
        xml.title_ @title
        # xml.updated '2012-01-01T12:00:00.594Z'
        xml.updated time.strftime("%Y-%m-%dT%T%Z") if time
        if @name
          xml.send(@name.tag) do
            @name.write(xml)
          end
        end
        values.each do |element|
          xml.send(element.tag, element.attribute_hash, element.value) do
            element.write(xml)
          end
        end
        xml.send('gContact:groupMembershipInfo', :deleted => 'false', :href => group_id)
      end
    end
    builder.to_xml
  end

  def self.retrieve(yt, id)
    yt.get('https://www.google.com/m8/feeds/contacts/default/full/' + id)
  end
end