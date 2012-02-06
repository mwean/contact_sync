class Contact
  attr_accessor :content, :id, :title, :name, :xml, :updated, :external_id

  def initialize(content_or_id, connection)
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

  def create_or_update_for(user)
    if user.contact_ids.include?(@external_id.id_value)
      contact_id = user.get_contact_by_external_id(@external_id).id
      user.connection.put(user.url + '/full/' + contact_id, write)
    else
      user.connection.post(user.url + '/full', write)
    end
  end

  def values
    members = []
    @content.each do |type, values|
      members << values unless values.empty?
    end
    members << @external_id
    members.flatten
  end

  def create
    contact_array = [%{<atom:entry xmlns:atom='http://www.w3.org/2005/Atom'
        xmlns:gd='http://schemas.google.com/g/2005'>
      <atom:category scheme='http://schemas.google.com/g/2005#kind'
        term='http://schemas.google.com/contact/2008#contact'/>}]

    @content.each do |name, element|
      if element.is_a?(Array)
        element.each do |member|
          contact_array << member.write
        end
      else
        contact_array << element.write
      end
    end

    contact_array << "</atom:entry>"

    contact_array.join(' ')
  end

  def update!
    @connection.put('https://www.google.com/m8/feeds/contacts/default/full/' + @id, write)
  end

  def read(xml)
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
      update!
    end

    @content
  end

  def generate_external_id
    ext_id = (@name.first_name[:value] + @name.last_name[:value] + Time.now.strftime("%Y%m%d%H%M")).downcase
    @external_id = ExternalId.new(ext_id)
  end

  def write
    builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      xml.entry(xmlns: 'http://www.w3.org/2005/Atom', 'xmlns:gContact' => 'http://schemas.google.com/contact/2008', 'xmlns:batch' => 'http://schemas.google.com/gdata/batch', 'xmlns:gd' => 'http://schemas.google.com/g/2005', 'gd:etag' => '*') do
        xml.category(
          scheme: "http://schemas.google.com/g/2005#kind",
          term: "http://schemas.google.com/contact/2008#contact"
        )
        xml.id_ "https://www.google.com/m8/feeds/contacts/default/base/#{@id}" if @id
        xml.title_ @title
        xml.send(@name.tag) do
          @name.write(xml)
        end
        values.each do |element|
          xml.send(element.tag, element.attribute_hash, element.value) do
            element.write(xml)
          end
        end
      end
    end
    @xml = builder.to_xml
  end

  def self.retrieve(yt, id)
    yt.get('https://www.google.com/m8/feeds/contacts/default/full/' + id)
  end
end