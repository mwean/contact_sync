class Session
  attr_accessor :users

  def initialize
    @users = []
    load_users
  end

  def load_users
    config_path = File.expand_path('../config/credentials.yaml', File.dirname(__FILE__))
    credentials = YAML.load(File.read(config_path))# .symbolize_keys!
    credentials['users'].each do |user, info|
      @users << User.new(info['email'], info['password'])
    end
  end

  def sync_users!
    new_contacts = {}

    @users.each do |user|
      user.get_contacts

      user.contacts.each do |contact|
        if new_contacts[contact.external_id.id_value]
          new_contacts[contact.external_id.id_value] = contact if contact.updated > new_contacts[contact.external_id.id_value].updated
        else
          new_contacts[contact.external_id.id_value] = contact
        end
      end
    end

    @users.each do |user|
      new_contacts.each do |external_id, contact|
        contact.create_or_update_for(user)
      end
    end
  end
end