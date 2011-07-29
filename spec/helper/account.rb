require 'yaml'

ACCOUNT = YAML.load_file(File.dirname(__FILE__) + '/account.yml')

def get_api
  Box::Api.new(ACCOUNT['api_key'])
end

def get_account(auth = true)
  Box::Account.new(get_api).tap do |account|
    account.authorize(ACCOUNT['auth_token']) if auth
  end
end

def get_root
  get_account.root
end
