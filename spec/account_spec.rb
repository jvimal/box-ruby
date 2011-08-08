require 'helper/account'

require 'box/api'
require 'box/account'

describe Box::Account do
  describe "without authorization" do
    before(:each) do
      @account = get_account(false)
    end

    it "fails to authorize without auth token" do
      @account.authorize.should == false
    end

    it "authorizes using auth token" do
      @account.authorize(ACCOUNT['auth_token']).should == true
    end
  end

  describe "with authorization" do
    before(:each) do
      @account = get_account
    end

    # TODO: We need a way to reauthorize automatically, because logout resets the auth token
    #it "can logout" do
    #  @account.logout.should == true
    #end

    it "gets the root folder" do
      @account.root.id.should == 0
    end

    it "caches the root folder" do
      @account.root.should be @account.root
    end
  end
end
