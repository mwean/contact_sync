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