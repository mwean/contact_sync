require 'signet'
# require 'oauth2'
# client = OAuth2::Client.new('1065131563486.apps.googleusercontent.com', 'SpNL27-tiLBvbgW_he9RX54a', :site => 'https://www.google.com/m8/feeds')
#
# client.auth_code.authorize_url(:redirect_uri => 'http://localhost:4567/oauth2/callback')
# # => "https://example.org/oauth/authorization?response_type=code&client_id=client_id&redirect_uri=http://localhost:8080/oauth2/callback"
#
# token = client.auth_code.get_token('authorization_code_value', :redirect_uri => 'http://localhost:4567/oauth2/callback')
# # response = token.get('/api/resource', :params => { 'query_foo' => 'bar' })
# # response.class.name
# # => OAuth2::Response



client = Signet::OAuth1::Client.new(
  :temporary_credential_uri =>
    'https://www.google.com/accounts/OAuthGetRequestToken',
  :authorization_uri =>
    'https://www.google.com/accounts/OAuthAuthorizeToken',
  :token_credential_uri =>
    'https://www.google.com/accounts/OAuthGetAccessToken',
  :client_credential_key => '1065131563486.apps.googleusercontent.com',
  :client_credential_secret => 'SpNL27-tiLBvbgW_he9RX54a'
)
client.fetch_temporary_credential!(:additional_parameters => {
  :scope => 'https://mail.google.com/mail/feed/atom'
})
# Send the user to client.authorization_uri, obtain verifier
client.fetch_token_credential!(:verifier => '12345')
response = client.fetch_protected_resource(
  :uri => 'https://mail.google.com/mail/feed/atom'
)