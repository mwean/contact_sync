class User
  attr_accessor :email, :password, :url, :contacts, :connection, :updated_contacts

  def initialize(email, password)
    @email = email
    @password = password
    @url = "http://www.google.com/m8/feeds/contacts/#{CGI.escape(@email)}"
    @contacts = []

    @connection = GData::Client::Contacts.new(version: 3)
    @connection.clientlogin(@email, @password)
  end

  def contact_ids
    @contacts.map { |c| c.external_id.id_value }
  end

  def updated_contacts(minutes_ago = 5)
    @contacts.select { |c| c.updated > minutes_ago.minutes.ago.utc.to_datetime }
  end

  def get_contact_by_external_id(external_id)
    @contacts.select { |c| c.external_id.id_value == external_id.id_value }.first
  end

  def sync_with(other_user, sync_range = 5)
    get_contacts

    other_user.get_contacts

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

  def get_contacts
    url = @url + '/full'
    response = @connection.get(url)
    parsed_response = Nokogiri::XML::Document.parse(response.body)
    parsed_response.css('entry').each { |e| @contacts << Contact.new(e, @connection) }
  end
end