require 'active_support/core_ext/numeric/time'
# require 'active_support/core_ext/hash/keys.rb'
require 'nokogiri'
require 'gdata'
require 'date'
require 'yaml'

$: << File.dirname(__FILE__)

files = %w{
  element
  wrapped_node
  name
  email
  im
  phone_number
  address
  organization
  external_id
  session
  user
  contact
  }

files.each { |file| require "lib/#{file}" }

REL = 'http://schemas.google.com/g/2005#'
CONTACTS_URL = 'https://www.google.com/m8/feeds/contacts/'

# u = User.new('tim@neon-lab.com', 'gimperson1')

# u.get_contacts
# p u.contacts.first.updated
# p u.contacts[0].updated
# p u.contacts[1].updated
# p u.contacts[0].newer_than?(u.contacts[1])
# s = Session.new
# p s.users[0].contacts['201204161307'].updated
# p s.users[1].contacts['201204161307'].updated
# p s.users[2].contacts['201204161307'].updated
# p s.users[2].contacts['mattwean201204161307'].update_for(s.users[2])
# s.sync_users!