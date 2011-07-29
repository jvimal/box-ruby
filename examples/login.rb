# add the lib directory to our require path (you do not need this if you install the box-api gem)
$: << File.dirname(__FILE__) + "/../lib"

# we use bundler to keep all of our gems up to date, but it is optional
require 'rubygems'
require 'bundler/setup'

# we're only using account specific features in this example, so we don't need to require the entire gem
require 'box/account'

# launchy is a simple gem that opens a browser, but is completely optional
require 'launchy'

# we save all of our app data to a file, so we don't have to hard-code values
app_data_file = File.dirname(__FILE__) + '/app_data.yml'
app_data = YAML.load_file(app_data_file)

# create an account object using the API key stored in app_data.yml
# you need to get your own API key at http://www.box.net/developers/services
account = Box::Account.new(app_data['api_key'])

# the user has to authorize your app on the box website, at which point you'll get an auth token
# this auth token works between sessions, so read it from disk if the user has authed before
auth_token = app_data['auth_token']

# now we have enough information to log into the box api, so we try to authorize using the auth token
authed = account.authorize(auth_token) do |auth_url|
  # this block is called if the auth_token is invalid or missing

  # we use launchy to open a new browser, but you can do it however you want
  Launchy.open(auth_url)

  # make sure you pause until the user has authorized, or just tell them to restart the program
  puts "Hit any key once you have logged in on the opened web page."
  gets
end

unless authed
  # the user didn't auth like we told them to, so we can't access anything
  puts "Unable to login, please try again."
  exit
end

# this auth token will let us instantly authorize next time this app is run, so we want to save it
# keep in mind that an auth token only works with the same api key, and will expire if the user logs out
app_data['auth_token'] = account.auth_token

# we write the auth_token to file so it can be accessed on next run
File.open(app_data_file, 'w') do |file|
  YAML.dump(app_data, file)
end

# we managed to log in successfully!
puts "Logged in as #{ account.info['login'] }"

# this is so the other example can access the account variable (bad practice)
@account = account
