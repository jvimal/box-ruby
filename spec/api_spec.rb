require 'box/api'

describe Box::Api do
  it "fails without api key" do
    lambda { Box::Api.new('').get_ticket }.should raise_error
  end

  it "fails with invalid api key" do
    lambda { Box::Api.new('invalidapikey').get_ticket }.should raise_error
  end

  it "fails with invalid url" do
    lambda { Box::Api.new('invalidapikey', 'http://google.com').get_ticket }.should raise_error
  end

  it "fails with invalid version" do
    lambda { Box::Api.new('invalidapikey', 'https://box.net', 'https://upload.box.net', '3.14').get_ticket }.should raise_error
  end
end
