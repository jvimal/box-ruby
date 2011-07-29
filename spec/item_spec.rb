require 'box/item'

describe Box::Item do
  class Fake < Box::Item
    def self.type; "fake"; end
    def get_info(*args); { :lol => 'fake' }; end
  end

  def fake(options = {})
    Fake.new(nil, nil, options)
  end

  it "has info accessors" do
    item = fake(:name => 'myname', :philip => 'king')
    item.name.should == 'myname'
    item.philip.should == 'king'
  end

  it "registers type correctly" do
    item = fake
    item.type.should == 'fake'
    item.types.should == 'fakes'
  end

  it "lazy-loads info" do
    item = fake
    item.data['lol'].should == nil
    item.lol.should == 'fake'
    item.data['lol'].should == 'fake'
  end

  it "trims unneeded attribute names" do
    item = fake(:fake_name => 'myname2', :fake_philip => 'king2', :file_name => 'nottrim')
    item.name.should == 'myname2'
    lambda { item.fake_name }.should raise_error
    item.philip.should == 'king2'
    item.file_name.should == 'nottrim'
  end

  it "uses the right path" do
    parent = fake(:name => 'my', :fakes => [])
    item = fake(:name => 'path')

    parent.path.should == "my"
    item.path.should == "path"

    item.parent = parent
    parent.path.should == "my"
    item.path.should == "my/path"
  end
end
