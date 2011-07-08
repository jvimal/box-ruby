require File.dirname(__FILE__) + '/test_helper.rb'
require "boxrubylib/boxclientlib"
require "test/unit"
include BoxClientLib

class TestBoxrubylib < Test::Unit::TestCase

  def setup
  end

  def showFolderInfo(folder)
    if (folder == nil)
      return
    end
    print("userId = #{folder.userId}\n")
    print("folderId = #{folder.folderId}\n")
    print("folderName = #{folder.folderName}\n")
    print("description = #{folder.description}\n")
    print("createDate = #{folder.createDate}\n")
    print("updateDate = #{folder.updateDate}\n")
    print("totalFolderSize = #{folder.totalFolderSize}\n")
    print("shared = #{folder.shared}\n")
    print("sharedLinkName = #{folder.sharedLinkName}\n")
    print("permissions = #{folder.permissions}\n")
    if (folder.fileList != nil)
      print("---   file list   ---\n")
      folder.fileList.each do |file|
        showFileInfo(file)
      end
      print("--- file list end ---\n")
    end
    if (folder.childFolderList != nil)
      print("---   child folder list   ---\n")
      folder.childFolderList.each do |childFolder|
        showFolderInfo(childFolder)
      end
      print("--- child folder list end ---\n")
    end
  end

  def showFileInfo(file)
    print("---   file   ---\n")
    print("fileId = #{file.fileId}\n")
    print("fileName = #{file.fileName}\n")
    print("description = #{file.description}\n")
    begin
      print("parentFolderId = #{file.parentFolderId}\n")
    rescue
    end
    print("sha1 = #{file.sha1}\n")
    print("createDate = #{file.createDate}\n")
    print("updateDate = #{file.updateDate}\n")
    print("size = #{file.size}\n")
    print("shared = #{file.shared}\n")
    print("sharedLinkName = #{file.sharedLinkName}\n")
    print("--- file end ---\n")
  end

  def showUserStorageInfo(usInfo)
    print("loginName = #{usInfo.loginName}\n")
    print("email = #{usInfo.email}\n")
    print("accessId = #{usInfo.accessId}\n")
    print("userId = #{usInfo.userId}\n")
    print("spaceAmount = #{usInfo.spaceAmount}\n")
    print("spaceUsed = #{usInfo.spaceUsed}\n")
  end

  def showCreatedFolderInfo(folder)
    print("userId = #{folder.userId}\n")
    print("folderId = #{folder.folderId}\n")
    print("folderName = #{folder.folderName}\n")
    print("folderPath = #{folder.folderPath}\n")
    print("shared = #{folder.shared}\n")
    print("sharedLinkName = #{folder.sharedLinkName}\n")
    print("parentFolderId = #{folder.parentFolderId}\n")
    print("password = #{folder.password}\n")
  end

  def showTagList(taglist)
    print("-- taglist start --\n")
    if (taglist != nil)
      taglist.each do |tag|
        print("tagId = #{tag.tagId}\n")
        print("description = #{tag.description}\n")
      end
    end
    print("--taglist end--\n")
  end

  def showFriendList(friendlist)
    print("-- friendlist start --\n")
    if (friendlist != nil)
      friendlist.each do |friend|
        print("friendName = #{friend.friendName}\n")
        print("email = #{friend.email}\n")
        print("accepted = #{friend.accepted}\n")
        print("avatarURL = #{friend.avatarURL}\n")
        print("boxList = #{friend.boxList}\n")
      end
    end
    print("--friendlist end--\n")
  end

  def test_start
    #You need to pass actual parameters bellow if you want to run this test case.
    emailAddress = "your_email@email.ne.jp"
    friendEmailAddress = "your_friend_emai@email.ne.jp"
    password = "your_account_password"
    notRegisteredEmail = "not_registered@email.ne.jp"
    publicName = "public_name"
    apiKey = "your_apprication_api_key"
    filePath = "./test.txt"
    tags = ["tag1", "tag2"]
    emails = [friendEmailAddress]

    box = BoxRestClient.new(apiKey)
    #login
    ticket = box.getTicket()
    while(true)
      begin
        print("You need to login at \n")
        print("http://www.box.net/api/1.0/auth/#{ticket}\n")
        print("from your Web browser.\n")
        print("If you finish login process, press any key.\n")
        STDIN.gets
        authToken = box.getAuthToken(ticket)
        break
      rescue
        print("Your login isn't success now.\nTry again?[Y/N]\n")
        c = STDIN.gets.chomp
        if ((c != 'y')&&(c != 'Y'))
          break
        end
      end
    end

    if (authToken == nil)
      exit(1)
    end

    printf("authtoken = %s\n", box.userStorageInfo.authToken)
    begin
      #Create folder as "tmptest1" on Root folder.
      createdFolder1 = box.createFolder(0, "tmptest1", 1)

      #Set description "tmptest1" folder.
      box.setDescription("folder", createdFolder1.folderId, "folder description.")
      showCreatedFolderInfo(createdFolder1)

      #Create folder as "tmptest2" on Root folder.
      createdFolder2 = box.createFolder(0, "tmptest2", 1)

      #Rename "tmptest2" folder to "renamed".
      box.rename("folder", createdFolder2.folderId, "renamed")

      #Move "renamed" folder to "tmptest1" folder.
      box.move("folder", createdFolder2.folderId, createdFolder1.folderId)

      #Get folder information simple mode.
      options = ["simple"]
      folder = box.getFolderInfo(createdFolder1.folderId, options)
      showFolderInfo(folder)

      f = open(filePath, "r")
      data = f.read
      f.close

      #File upload to "tmptest1" folder.
      uploadedFileInfo = box.fileUpload("test.txt", data, createdFolder1.folderId, 1, nil, nil)

      #File copy "test.txt" on "tmptest1" folder as "test2.txt".
      uploadedFileInfo = box.fileNewCopy("test2.txt", data, uploadedFileInfo.fileId, 1, "message", emails)

      #File over write "test.txt" to "test2.txt".(Only over write data. File name is still "test2.txt".)
      box.fileOverWrite("test.txt", data, uploadedFileInfo.fileId, 1, nil, nil)

      #File move "test2.txt" to "renamed" folder.
      box.move("file", uploadedFileInfo.fileId, createdFolder2.folderId)

      #Set description test2.txt as "$$$description$$$"
      box.setDescription("file", uploadedFileInfo.fileId, "$$$description$$$")
      file = box.getFileInfo(uploadedFileInfo.fileId)

      #"test2.txt" is public shared with password "password".
      box.publicShare("file", uploadedFileInfo.fileId, "password", "This file is public shared!", nil)

      #Add to tag "tag1" "tag2" to "test2.txt"
      box.addToTag("file", uploadedFileInfo.fileId, tags)
      showFileInfo(file)

      #"test2.txt" is public unshared.
      box.publicUnshare("file", uploadedFileInfo.fileId)

      #"test2.txt" is private shared.
      box.privateShare("file", uploadedFileInfo.fileId, "This file is private shared!", emails, 0)

      #Enabled SSL.
      box.useSSL = true
      data = box.fileDownload(uploadedFileInfo.fileId)

      f = open(filePath, "w")
      f.write(data)
      f.close

      #Get folder information about "tmptest1" folder.
      folder = box.getFolderInfo(createdFolder1.folderId, nil)
      showFolderInfo(folder)

      #Disabled SSL.
      box.useSSL = false
      box.delete("folder", createdFolder1.folderId)

      #Update user storage information.
      box.updateUserStorageInfo
      showUserStorageInfo(box.userStorageInfo)

      #Get root folder information.
      options = ["simple", "onelevel"]
      folder = box.getRootFolderInfo(options)
      showFolderInfo(folder)

      #Request friends.
      options = ["no_email"]
      box.requestFriends("Request friends.", emails, options)

      #Verify email what is not registered box.net.
      box.verifyRegistrationEmail(notRegisteredEmail)

      #box.registerNewUser("new@username.ne.jp", "password")

      #Get tag list.
      taglist = box.exportTag
      showTagList(taglist)

      #Get friend list.
      friendList = box.getFriends
      showFriendList(friendList)

      #Get other user's shared file to my box.
      box.addToMyStorage("file", nil, publicName, 0, tags)
    ensure
      #Logout.
      box.logout
    end
  end
end
