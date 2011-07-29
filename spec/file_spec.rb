require 'helper/account'

require 'box/api'
require 'box/account'
require 'box/file'
require 'box/folder'

describe Box::File do
  describe "operations" do
    before(:all) do
      @root = get_root
      spec = @root.find(:name => 'rspec folder', :type => 'folder').first
      spec.delete if spec
    end

    before(:each) do
      @hello_file = 'dummy.test'
      File.open(@hello_file, 'w') { |f| f.write("Hello World!") }

      @vegetables = 'veg.test'
      File.open(@vegetables, 'w') { |f| f.write("banana, orange, avachokado") }

      @test_root = @root.create('rspec folder')
      @dummy = @test_root.upload(@hello_file)
    end

    after(:each) do
      File.delete(@hello_file)
      File.delete(@vegetables)

      @test_root.delete
    end

    it "gets file info" do
      @dummy.name.should_not == nil
    end

    it "lazy-loads file info" do
      @dummy.data['sha1'].should == nil
      @dummy.sha1.should_not == nil
      @dummy.data['sha1'].should_not == nil
    end

    it "uploads a new file" do
      @dummy.parent.should be @test_root
      @dummy.name.should == 'dummy.test'
    end

    it "uploads a copy" do
      file = @dummy.upload_copy(@vegetables)

      file.name.should == 'dummy (1).test'
      file.parent.should be @test_root
      file.sha1.should_not == @dummy.sha1

      @test_root.files.should have(2).things
    end

    it "overwrites a file" do
      temp = @dummy.sha1
      @dummy.upload_overwrite(@vegetables)

      @dummy.parent.should be @test_root
      @dummy.name.should == 'dummy.test'
      @dummy.sha1.should_not == temp

      @test_root.files.should have(1).things
    end

    it "downloads a file" do
      @dummy.download('dummy.down')
      `diff #{ @hello_file } dummy.down`.should == ""

      File.delete('dummy.down')
    end

    it "moves a file" do
      @test_temp = @test_root.create('temp')

      @dummy.move(@test_temp)
      @dummy.parent.should be @test_temp
    end

    it "copies a file" do
      @test_temp = @test_root.create('temp')
      clone = @dummy.copy(@test_temp)

      clone.parent.should be @test_temp
      clone.name.should == @dummy.name
      clone.should_not be @dummy
    end

    it "renames a file" do
      @dummy.rename('bandito.txt')
      @dummy.name.should == 'bandito.txt'
    end

    it "deletes a folder" do
      @dummy.delete

      @dummy.parent.should be nil
      @test_root.files.should have(0).things
    end
  end
end
