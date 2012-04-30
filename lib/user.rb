class User
  attr_accessor :email, :password, :url, :contacts, :connection, :updated_contacts, :group_id, :changes, :time

  def initialize(email, password, time = nil)
    @entries = {}
    @email = email
    @password = password
    @url = "http://www.google.com/m8/feeds/contacts/#{CGI.escape(@email)}"
    @time = time
    @contacts = {}
    
    @id_map = {}

    @connection = GData::Client::Contacts.new(version: 3)
    @connection.clientlogin(@email, @password)
    
    get_group_id
    get_contacts
    
    @old_contacts = @contacts.dup
    
    @contacts.each do |external_id, contact|
      @id_map[external_id] = contact.id
    end
    
    @changes = { create: [], update: [], delete: [] }
  end

  def contact_ids
    @contact_ids ||= @contacts.keys
  end
  
  def newest(*versions)
    versions.sort_by(&:updated).last
  end
  
  def merge(other_user)
    all_ids = (contact_ids + other_user.contact_ids).uniq
    result = {}
    all_ids.each do |id|
      if @contacts[id] && @contacts[id].marked_for_deletion
        # ---nothing
      elsif @contacts[id] && other_user.contacts[id]
        @contacts[id] = newest(@contacts[id], other_user.contacts[id])
      elsif @contacts[id]
        mark_for_deletion(@contacts[id])
      elsif other_user.contacts[id]
        @contacts[id] = other_user.contacts[id]
      end
    end
  end
  
  def update_from_original
    @contacts.each do |id, contact|
      if @old_contacts[id]
        # if id == 'elikanal201204031405'
        # p contact.newer_than?(@old_contacts[id])
        # p contact.updated# .strftime("%D %H:%M")
        # p contact.content[:addresses]
        # p '----'
        # p @old_contacts[id].updated# .strftime("%D %H:%M")
        # p @old_contacts[id].content[:addresses]
        # p '===================='
        # end
        
        contact.id = @id_map[id]
        if contact.marked_for_deletion
          @changes[:delete] << contact
        elsif contact.newer_than?(@old_contacts[id])
          @changes[:update] << contact
        end
      else
        @changes[:create] << contact
      end
    end
  end
  
  def update_with(master_contacts)
    #     p '============='
    #     p @email
    master_contacts.each do |id, contact|
      #           p '-------------'
      #           p contact.external_id.id_value
      # p           contact.updated
      # p           @contacts[id].updated
      #           p (contact.updated.to_time - @contacts[id].updated.to_time)
      
      
      if contact_ids.include?(id)
        contact.id = @id_map[id]
        if contact.marked_for_deletion
          @changes[:delete] << contact
        elsif contact.newer_than?(@contacts[id])
          @changes[:update] << contact
        end
      elsif !contact.marked_for_deletion
        @changes[:create] << contact
      end
    end
  end
  
  def write_changes!
    @changes[:create].each do |contact|
      contact.create_for(self)
    end
    
    @changes[:update].each do |contact|
      contact.update_for(self, @time)
    end
    
    @changes[:delete].each do |contact|
      contact.delete_for(self)
    end
    # builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
    #   xml.feed(xmlns: 'http://www.w3.org/2005/Atom', 'xmlns:gContact' => 'http://schemas.google.com/contact/2008', 'xmlns:batch' => 'http://schemas.google.com/gdata/batch', 'xmlns:gd' => 'http://schemas.google.com/g/2005') do
    #     @changes.each do |type, contacts|
    #       change(type, xml, contacts)
    #     end
    #   end
    # end
    # # puts builder.to_xml
    # @connection.post('http://www.google.com/m8/feeds/contacts/default/full/batch', builder.to_xml)
  end
  
  def change(type, xml, contacts)
    contacts.each do |contact|
      if type == :create
        xml.entry do
          xml['batch'].id_ "create#{rand(99999)}"
          xml['batch'].operation(type: 'insert')
          contact.create_or_update(xml, @group_id)
        end
      elsif type == :update
        xml.entry('gd:etag' => '*') do
          xml['batch'].id_ "update#{rand(99999)}"
          xml['batch'].operation(type: 'update')
          contact.create_or_update(xml, @group_id)
        end
      else
        xml.entry('gd:etag' => contact.etag) do
          xml['batch'].id_ "delete#{rand(99999)}"
          xml['batch'].operation(type: 'delete')
          xml.category(
          scheme: "http://schemas.google.com/g/2005#kind",
          term: "http://schemas.google.com/contact/2008#contact"
          )
          xml.id_ "http://www.google.com/m8/feeds/contacts/default/full/#{contact.id}"
        end
      end
    end
  end
  
  #     <batch:id>this-is-my-fourth-batch-request</batch:id>
  #     <batch:operation type="delete"/>
  # 
  #     <category scheme="http://schemas.google.com/g/2005#kind"
  # term="http://schemas.google.com/g/2008#contact"/>
  #     <id>http://www.google.com/m8/feeds/contacts/default/full/012345</id>
  #     <link rel="edit" type="application/atom+xml"
  # href="http://www.google.com/m8/feeds/contacts/default/full/012345/1204720598835123"/>

  # def updated_contacts(minutes_ago = 5)
  #   @contacts.select { |c| c.updated > minutes_ago.minutes.ago.utc.to_datetime }
  # end

  # def get_contact_by_external_id(external_id)
  #   @contacts.select { |c| c.external_id.id_value == external_id.id_value }.first
  # end
  
  def mark_for_deletion(contact)
    contact.marked_for_deletion = true
    contact
  end
  
  def delete!(contact)
    @contacts.delete(contact.external_id.id_value)
  end

  def sync_with(other_user, sync_range = 5)
    updated_count = 0

    if sync_range == :all
      @contacts.each do |contact|
        contact.create_or_update_for(other_user)

        updated_count += 1
      end

      other_user.contacts.each do |contact|
        contact.create_or_update_for(self)
        updated_count += 1
      end
    elsif sync_range.is_a?(Integer)
      updated_contacts(sync_range).each do |contact|
        contact.create_or_update_for(other_user)
        updated_count += 1
      end

      other_user.updated_contacts(sync_range).each do |contact|
        contact.create_or_update_for(self)
        updated_count += 1
      end
    end

    output = updated_count.to_s
    output += updated_count == 1 ? 'contact' : 'contacts'
    output += 'synced'
    puts output
  end
  
  def parse_from_url(url)
    response = @connection.get(url)
    Nokogiri::XML::Document.parse(response.body)
  end
  
  def entries(url)
    @entries[url] ||= parse_from_url(url).css('entry')
  end
  
  def get_group_id
    url = @url.sub(/contacts/, 'groups') + '/full'
    entries(url).each do |entry|
      contact_group = entry.css('gContact|systemGroup')[0]
      @group_id = entry.css('id').inner_html if contact_group && contact_group['id'] =='Contacts'
    end
  end

  def get_contacts
    url = @url + '/full'
    entries(url).each do |entry|
      c = Contact.new(entry, @connection, self)
      @contacts[c.external_id.id_value] = c
    end
  end
end