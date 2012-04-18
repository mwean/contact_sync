class Session
  attr_accessor :users, :master, :time

  def initialize
    @users = []
    @time = DateTime.now
    load_users
  end

  def load_users
    @master = User.new('master@neon-lab.com', 'gimperson1', @time)
    
    config_path = File.expand_path('../config/credentials.yaml', File.dirname(__FILE__))
    credentials = YAML.load(File.read(config_path))
    credentials['users'].each do |user, info|
      @users << User.new(info['email'], info['password'], @time)
    end
  end

  def sync_users!
    update_master
    update_users
  end
  
  def update_users
    @users.each do |user|
      user.update_with(@master.contacts)
      # p user.email
      # p user.changes
      # p '------'
      user.write_changes!
    end
  end
  
  def update_master
    @users.each do |user|
      @master.merge(user)
    end
    # p temp_changes['elikanal201204031405'].content[:addresses]
    @master.update_from_original
# p     @master.changes
    @master.write_changes!
  end
end