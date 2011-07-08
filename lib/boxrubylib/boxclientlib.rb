#= boxclientlib.rb
#Author:: Tomohiko Ariki, Makoto Kobayashi
#CopyRights:: Canon Software Inc.
#Created date:: 2009/06/10
#Last Modified:: 2009/11/09
#Version:: 1.0.1
#
#This file contains Box.net service class.

require "boxrubylib/restclientlib"

module BoxClientLib
  #Box.net client class.
  #
  #class valiable:
  # @@server - Box.net URL ("www.box.net").
  # @@upload - Upload URL ("upload.box.net").
  # @@apiPath - Box.net rest api path ("/api/1.0/rest").
  # @@header - HTTP header to get/post method.
  #
  #attributes:
  # userStorageInfo - User's Box.net storage information.
  class BoxRestClient < RestClientLib::RestClient
    @@server = "www.box.net"
    @@port = 80
    @@sslPort = 443
    @@upload = "upload.box.net"
    @@apiPath = "/api/1.0/rest"
    @@header = {
      "User-Agent" => "boxclientlib/0.0.2\r\n"
    }
    attr_accessor :apiKey, :userStorageInfo

    # Constructor.
    #
    #  You must set Api key
    def initialize(apiKey)
      super()
      @apiKey = apiKey
    end

    # Request ticket to receive auth token.
    #
    # [Return value]
    #  Ticket(string value).
    def getTicket
      params = {
        "action" => "get_ticket",
        "api_key" => @apiKey
      }
      doc = getRequest(@@server, @useSSL == false ? @@port : @@sslPort, @@apiPath, params, @@header)
      checkError(doc, "get_ticket_ok")

      return doc.elements["/response/ticket"].text
    end

    # Get auth token to call Box.net API.
    #  [ticket]
    #   Ticket to get auth token.
    #
    # [Return value]
    #  Auth token. (And it will be set instance value - @userStorageInfo.)
    def getAuthToken(ticket)
      params = {
        "action" => "get_auth_token",
        "api_key" => @apiKey,
        "ticket" => ticket
      }
      doc = getRequest(@@server, @useSSL == false ? @@port : @@sslPort, @@apiPath, params, @@header)
      checkError(doc, "get_auth_token_ok")
      @userStorageInfo = UserStorageInfo.new(doc.elements['/response/user'])
      return @userStorageInfo.authToken = doc.elements['/response/auth_token'].text
    end

    # Logout.
    #
    # [Return value]
    #  True, if success.
    def logout
      params = {
        "action" => "logout",
        "api_key" => @apiKey,
        "auth_token" => @userStorageInfo == nil ? "" : @userStorageInfo.authToken
      }
      doc = getRequest(@@server, @useSSL == false ? @@port : @@sslPort, @@apiPath, params, @@header)
      return checkError(doc, "logout_ok")
    end

    # Regist new user.
    #
    # [login]
    #  Login user name to regist.
    # [password]
    #  Password for new user to regist.
    #
    # [Return value]
    #  True, if success.
    def registerNewUser(login, password)
      params = {
        "action" => "register_new_user",
        "api_key" => @apiKey,
        "login" => login,
        "password" => password
      }
      sslFlag = @useSSL
      begin
        doc = getRequest(@@server, @useSSL == false ? @@port : @@sslPort, @@apiPath, params, @@header)
      ensure
        @useSSL = sslFlag
      end
      return checkError(doc, "successful_register")
    end

    # This method is used to verify whether a user email is available, or already in use.
    #
    # [userName]
    #  The login username of the user for which you would like to verify registration.
    #
    # [Return value]
    #  True, if user email is available to register.
    def verifyRegistrationEmail(login)
      params = {
        "action" => "verify_registration_email",
        "api_key" => @apiKey,
        "login" => login
      }
      doc = getRequest(@@server, @useSSL == false ? @@port : @@sslPort, @@apiPath, params, @@header)
      return checkError(doc, "email_ok")
    end

    # Update user's storage information.
    #
    # [Return value]
    #  True, if success. (And it will be set instance value - @userStorageInfo.)
    def updateUserStorageInfo
      params = {
        "action" => "get_account_info",
        "api_key" => @apiKey,
        "auth_token" => @userStorageInfo.authToken
      }
      doc = getRequest(@@server, @useSSL == false ? @@port : @@sslPort, @@apiPath, params, @@header)
      checkError(doc, "get_account_info_ok")
      @userStorageInfo.loginName = doc.elements['/response/user/login'].text
      @userStorageInfo.email = doc.elements['/response/user/email'].text
      @userStorageInfo.accessId = doc.elements['/response/user/access_id'].text
      @userStorageInfo.userId = doc.elements['/response/user/user_id'].text
      @userStorageInfo.spaceAmount = doc.elements['/response/user/space_amount'].text
      @userStorageInfo.spaceUsed = doc.elements['/response/user/space_used'].text

      return true
    end

    # File & Folder Operations

    # Get folder info from root folder.
    #
    # [options]
    #  Array of to get folder info option parameter(s).you can set follows value(s).
    #  "onelevel" - Get one level of folder info.
    #  "nofiles" - Get folder info without file info.
    #  "simple" - Get simple info only(thumbnails, shared status, tags, and other attributes are left out).
    #
    # [Return value]
    #  Root folder information.
    def getRootFolderInfo(options)
      return getFolderInfo(0, options)
    end

    # Get target folder info.
    # [folderId]
    #  Folder ID to get folder info.
    # [options]
    #  Array of to get folder info option parameter(s).you can set follows value(s).
    #  "onelevel" - Get one level of folder info.
    #  "nofiles" - Get folder info without file info.
    #  "simple" - Get simple info only(thumbnails, shared status, tags, and other attributes are left out).
    # [Return value]
    #  Target folder information.
    def getFolderInfo(folderId, options)
      options = Array.new if (options.nil?)
      options.push("nozip") if (options.index("nozip").nil?)
      params = {
        "action" => "get_account_tree",
        "api_key" => @apiKey,
        "auth_token" => @userStorageInfo.authToken,
        "folder_id" => folderId,
        "params[]" => options
      }
      doc = getRequest(@@server, @useSSL == false ? @@port : @@sslPort, @@apiPath, params, @@header)
      checkError(doc, "listing_ok")

      return FolderInfo.new(doc.elements['/response/tree/folder'])
    end

    # Create folder.
    #
    # [parentId]
    #  Parent folder ID.
    # [name]
    #  Folder name it will be created.
    # [share]
    #  1 - share, 0 - not share.
    #
    # [Return value]
    #  Created folder information.
    def createFolder(parentId, name, share)
      params = {
        "action" => "create_folder",
        "api_key" => @apiKey,
        "auth_token" => @userStorageInfo.authToken,
        "parent_id" => parentId,
        "name" => name,
        "share" => share
      }
      doc = getRequest(@@server, @useSSL == false ? @@port : @@sslPort, @@apiPath, params, @@header)
      checkError(doc, "create_ok")

      return CreatedFolderInfo.new(doc.elements['/response/folder'])
    end

    # Move file or folder.
    #
    # [target]
    #  The type of item to be moved.  Can be 'file' or 'folder'.
    # [targetId]
    #  The id of the item you wish to move.
    # [destinationId]
    #  The folder_id of the folder to which you will move the item.
    #
    # [Return value]
    #  True, if success.
    def move(target, targetId, destinationId)
      params = {
        "action" => "move",
        "api_key" => @apiKey,
        "auth_token" => @userStorageInfo.authToken,
        "target" => target,
        "target_id" => targetId,
        "destination_id" => destinationId
      }
      doc = getRequest(@@server, @useSSL == false ? @@port : @@sslPort, @@apiPath, params, @@header)
      return checkError(doc, "s_move_node")
    end

    # Rename file or folder.
    #
    # [target]
    #  The type of item to be renamed.  Can be 'file' or 'folder'.
    # [targetId]
    #  The id of the item you wish to rename.
    # [newName]
    #  The new name to be applied to the item.
    #
    # [Return value]
    #  True, if success.
    def rename(target, targetId, newName)
      params = {
        "action" => "rename",
        "api_key" => @apiKey,
        "auth_token" => @userStorageInfo.authToken,
        "target" => target,
        "target_id" => targetId,
        "new_name" => newName
      }
      doc = getRequest(@@server, @useSSL == false ? @@port : @@sslPort, @@apiPath, params, @@header)
      return checkError(doc, "s_rename_node")
    end

    # Delete file or folder.
    #
    # [target]
    #  The type of item to be deleted.  Can be 'file' or 'folder'.
    # [targetId]
    #  The id of the item you wish to delete.
    #
    # [Return value]
    #  True, if success.
    def delete(target, targetId)
      params = {
        "action" => "delete",
        "api_key" => @apiKey,
        "auth_token" => @userStorageInfo.authToken,
        "target" => target,
        "target_id" => targetId,
      }
      doc = getRequest(@@server, @useSSL == false ? @@port : @@sslPort, @@apiPath, params, @@header)
      return checkError(doc, "s_delete_node")
    end

    # Get the file information.
    #
    # [fileId]
    #  The id of the file for with you want to obtain more information.
    #
    # [Return value]
    #  File information.
    def getFileInfo(fileId)
      params = {
        "action" => "get_file_info",
        "api_key" => @apiKey,
        "auth_token" => @userStorageInfo.authToken,
        "file_id" => fileId
      }
      doc = getRequest(@@server, @useSSL == false ? @@port : @@sslPort, @@apiPath, params, @@header)
      checkError(doc, "s_get_file_info")

      return FileInfo.new(doc.elements['/response/info'])
    end

    # Set description file or folder.
    #
    # [target]
    #  The type of item to set description.  Can be 'file' or 'folder'.
    # [targetId]
    #  The id of the item you wish to set description.
    # [description]
    #  File or folder description.
    #
    # [Return value]
    #  True, if success.
    def setDescription(target, targetId, description)
      params = {
        "action" => "set_description",
        "api_key" => @apiKey,
        "auth_token" => @userStorageInfo.authToken,
        "target" => target,
        "target_id" => targetId,
        "description" => description
      }
      doc = getRequest(@@server, @useSSL == false ? @@port : @@sslPort, @@apiPath, params, @@header)
      return checkError(doc, "s_set_description")
    end

    # Upload file (If same file name is already exist target folder, it will be overwritten).
    #
    # [fileName]
    #  Name of the upload file.
    # [data]
    #  File contents.
    # [targetId]
    #  Folder ID to upload.
    # [shareValue]
    #  1 - share, 0 - not share.
    # [message]
    #  An message to be included in a notification email, if the file will be shared with others.
    # [emails]
    #  email addresses to notify him or her about file uploaded.if you want to send 2 or more
    #  email address, you set to "emails" parameter to Array type.
    #
    # [Return value]
    #  Uploaded file information.
    def fileUpload(fileName, data, targetId, shareValue, message, emails)
      params = setUploadParameter(shareValue, message, emails)
      uri = "/api/1.0/upload/#{@userStorageInfo.authToken}/#{targetId}"
      doc = postRequest(@@upload, @useSSL == false ? @@port : @@sslPort, uri, fileName, data, params, @@header)
      checkError(doc, "upload_ok")

      return UploadedFileInfo.new(doc.elements['/response/files/file'])
    end

    # Upload file (Over write particular file).
    #
    # [fileName]
    #  Name of the upload file.
    # [data]
    #  File contents.
    # [targetId]
    #  File ID to overwrite.
    # [shareValue]
    #  1 - share, 0 - not share.
    # [message]
    #  An message to be included in a notification email, if the file will be shared with others.
    # [emails]
    #  email addresses to notify him or her about file uploaded.if you want to send 2 or more
    #  email address, you set to "emails" parameter to Array type.
    #
    # [Return value]
    #  Uploaded file information.
    def fileOverWrite(fileName, data, targetId, shareValue, message, emails)
      params = setUploadParameter(shareValue, message, emails)
      uri = "/api/1.0/overwrite/#{@userStorageInfo.authToken}/#{targetId}"
      doc = postRequest(@@upload, @useSSL == false ? @@port : @@sslPort, uri, fileName, data, params, @@header)
      checkError(doc, "upload_ok")

      return UploadedFileInfo.new(doc.elements['/response/files/file'])
    end

    # Upload file (uploaded file's name will be "Copy of original-file-name").
    #
    # [fileName]
    #  Name of the upload file.
    # [data]
    #  File contents.
    # [targetId]
    #  File ID to origin.
    # [shareValue]
    #  1 - share, 0 - not share.
    # [message]
    #  An message to be included in a notification email, if the file will be shared with others.
    # [emails]
    #  email addresses to notify him or her about file uploaded.if you want to send 2 or more
    #  email address, you set to "emails" parameter to Array type.
    #
    # [Return value]
    #  Uploaded file information.
    def fileNewCopy(fileName, data, targetId, shareValue, message, emails)
      params = setUploadParameter(shareValue, message, emails)
      uri = "/api/1.0/new_copy/#{@userStorageInfo.authToken}/#{targetId}"
      doc = postRequest(@@upload, @useSSL == false ? @@port : @@sslPort, uri, fileName, data, params, @@header)
      checkError(doc, "upload_ok")

      return UploadedFileInfo.new(doc.elements['/response/files/file'])
    end

    # Download file.
    #
    # [targetId]
    #  Download file ID.
    #
    # [Return value]
    #  File data.
    def fileDownload(targetId)
      uri = "/api/1.0/download/#{@userStorageInfo.authToken}/#{targetId}"

      return httpGetRequest(@@server, @useSSL == false ? @@port : @@sslPort, uri, @@header)
    end

    # Sharing

    # Make a file or folder shareable.
    #
    # [target]
    #  The type of item to share.  Can be 'file' or 'folder'.
    # [targetId]
    #  The id of the item you wish to share.
    # [password]
    #  New password to be applied to the shared item.
    # [message]
    #  An message to be included in a notification email.
    # [emails]
    #  An array of emails for which to notify users about the newly shared file or folder.
    #  If you don't want to notify, you can pass this parameter to nil.
    #
    # [Return value]
    #  Public name.
    def publicShare(target, targetId, password, message, emails)
      params = {
        "action" => "public_share",
        "api_key" => @apiKey,
        "auth_token" => @userStorageInfo.authToken,
        "target" => target,
        "target_id" => targetId,
        "password" => password,
        "message" => message,
        "emails[]" => emails
      }
      doc = getRequest(@@server, @useSSL == false ? @@port : @@sslPort, @@apiPath, params, @@header)
      checkError(doc, "share_ok")

      return doc.elements["/response/public_name"].text
    end

    # Unshare a public folder or file.
    #
    # [target]
    #  The type of item to set description.  Can be 'file' or 'folder'.
    # [targetId]
    #  The id of the item you wish to unshare.
    #
    # [Return value]
    #  True, if success.
    def publicUnshare(target, targetId)
      params = {
        "action" => "public_unshare",
        "api_key" => @apiKey,
        "auth_token" => @userStorageInfo.authToken,
        "target" => target,
        "target_id" => targetId
      }
      doc = getRequest(@@server, @useSSL == false ? @@port : @@sslPort, @@apiPath, params, @@header)
      return checkError(doc, "unshare_ok")
    end

    # Share a private folder or file.
    #
    # [target]
    #  The type of item to set description. Can be 'file' or 'folder'.
    # [targetId]
    #  The id of the item you wish to private share.
    # [message]
    #  An message to be included in a notification email.
    # [emails]
    #  An array of emails for which to share (and notify) users about the newly shared file or folder. Not allowed nil.
    # [notify]
    #  1 - notification email will be sent to users, 0 - not notification.
    #
    # [Return value]
    #  True, if success.
    def privateShare(target, targetId, message, emails, notify)
      params = {
        "action" => "private_share",
        "api_key" => @apiKey,
        "auth_token" => @userStorageInfo.authToken,
        "target" => target,
        "target_id" => targetId,
        "message" => message,
        "emails[]" => emails,
        "notify" => notify == 0 ? "false" : "true"
      }
      doc = getRequest(@@server, @useSSL == false ? @@port : @@sslPort, @@apiPath, params, @@header)
      return checkError(doc, "private_share_ok")
    end

    # Request new friends to be added to the user's friend list.
    #
    # [message]
    #  An message to be included in a notification email.
    # [emails]
    #  An array of emails for which to notify users to be added user's friend list.
    # [options]
    #  Array of option parameter. See below - parameter values.
    #  "box_auto_subscribe" - Subscribe to the public boxes of invited users.
    #  "no_email" - Do not send emails to the invited users.
    #
    # [Return value]
    #  True, if success.
    def requestFriends(message, emails, options)
      params = {
        "action" => "request_friends",
        "api_key" => @apiKey,
        "auth_token" => @userStorageInfo.authToken,
        "message" => message,
        "emails[]" => emails,
        "params[]" => options
      }
      doc = getRequest(@@server, @useSSL == false ? @@port : @@sslPort, @@apiPath, params, @@header)
      return checkError(doc, "s_request_friends")
    end

    # Retrieve user's friend list.
    #
    # [Return value]
    #  Friend list.
    def getFriends
      params = {
        "action" => "get_friends",
        "api_key" => @apiKey,
        "auth_token" => @userStorageInfo.authToken,
        "params[]" => "nozip"
      }
      doc = getRequest(@@server, @useSSL == false ? @@port : @@sslPort, @@apiPath, params, @@header)
      checkError(doc, "s_get_friends")
      friendList = Array.new
      doc.elements.each('/response/friends/friend') do |friendElement|
        friendList.push(TagInfo.new(friendElment))
      end

      return friendList
    end

    # Add to user's storage from publicly shared by another.
    #
    # [target]
    #  The type of item to set description. Can be 'file' or 'folder'.
    # [fileId]
    #  The id of the file you wish to add user's storage. If you will pass a value to publicName, you must pass this parameter - nil.
    # [publicName]
    #  The unique public name of the shared file that you wish to add to user's storage. If you will pass a value to fileId, you must pass this parameter - nil.
    # [folderId]
    #  The folder ID of the folder to which you will add user to user's storage.
    # [tags]
    #  An array of tags for which to apply to the file or folder.
    #
    # [Return value]
    #  True, if success.
    def addToMyStorage(target, fileId, publicName, folderId, tags)
      params = {
        "action" => "add_to_mybox",
        "api_key" => @apiKey,
        "auth_token" => @userStorageInfo.authToken,
        "file_id" => fileId,
        "target" => target,
        "public_name" => publicName,
        "folder_id" => folderId,
        "tags[]" => tags
      }
      doc = getRequest(@@server, @useSSL == false ? @@port : @@sslPort, @@apiPath, params, @@header)
      return checkError(doc, "addtomybox_ok")
    end

    # Tags

    # Add to a tag or tags to a designated file or folder.
    #
    # [target]
    #  The type of item to add to tag(s). Can be 'file' or 'folder'.
    # [targetId]
    #  The id of the item you wish to add to tag(s).
    # [tags]
    #  An array of tags for which to apply to the file or folder.
    #
    # [Return value]
    #  True, if success.
    def addToTag(target, targetId, tags)
      params = {
        "action" => "add_to_tag",
        "api_key" => @apiKey,
        "auth_token" => @userStorageInfo.authToken,
        "target" => target,
        "target_id" => targetId,
        "tags[]" => tags
      }
      doc = getRequest(@@server, @useSSL == false ? @@port : @@sslPort, @@apiPath, params, @@header)
      return checkError(doc, "addtotag_ok")
    end

    #This method returns all the tags in a user's account.
    #
    # [Return value]
    #  Tag info list.
    def exportTag
      params = {
        "action" => "export_tags",
        "api_key" => @apiKey,
        "auth_token" => @userStorageInfo.authToken
      }
      doc = getRequest(@@server, @useSSL == false ? @@port : @@sslPort, @@apiPath, params, @@header)
      checkError(doc, "export_tags_ok")
      tagList = Array.new
      doc.elements.each('/response/tags/tag') do |tagElement|
        tagList.push(TagInfo.new(tagElement))
      end
      return tagList
    end

    # Direct login to Box.net.
    # Notice:
    # This method need to authorized API key.
    # If you need to direct login, apply your own API key and authorization it by Box.net.
    # If you do, you can use this methos same like bellow.
    # box = BoxRestClient.new
    # box.apiKey = yourOwnAuthorizedApiKey
    # box.directLogin("login", "password")
    #
    # [loginName]
    #  Login email address.
    # [password]
    #  Login password.
    #
    # [Return value]
    #  Auth token - if success login. nil - if not success login.
    def login(loginName, password)
      apiKeyExpression = "<http://"+@@server+@@apiPath+"?action=authorization&api_key=><"+@apiKey+">"
      loginExpression = loginName + "<mailto:&login=" + loginName + ">"
      authToken = nil

      sslFlag = @useSSL
      ticket = getTicket()
      params = {
        "action" => "authorization",
        "api_key" => apiKeyExpression,
        "login" => loginExpression,
        "password" => password,
        "method" => nil
      }
      @useSSL = true
      begin
          doc = getRequest(@@server, @@sslPort, @@apiPath, params, @@header)
          checkError(doc, "logged")
          @userStorageInfo = UserStorageInfo.new(doc.elements['/response/user'])
          @userStorageInfo.authToken = doc.elements['/response/auth_token'].text
          authToken = @userStorageInfo.authToken
      ensure
        @useSSL = sslFlag
      end
      return authToken
    end

    private
    def checkError(doc, success)
      status = doc.elements['/response/status'].text
      unless status == success
        raise BoxServiceError.new(status)
      end
      return true
    end

    def setUploadParameter(shareValue, message, emails)
      params = {
        "share" => shareValue
      }
      params["message"] = message if (message != nil)
      params["emails[]"] = emails if (emails != nil)
      return params
    end
  end

  #Box.net service exception class.
  #
  #attributes:
  # errStatus - Error status.
  class BoxServiceError < StandardError
    attr_reader :errStatus

    # Constructor.
    #
    # [errStatus]
    #  Error status.
    def initialize(errStatus)
      @errStatus = errStatus
    end

    # Error status to string.
    #
    # [Return value]
    #  Error status string.
    def to_s
      "Box.net Service Error: #{@errStatus}"
    end
  end

  #Logined user's storage information class.
  #
  #attributes:
  # authToken - Auth token. It's necessary to call Box.net api.
  # loginName - Logined user name.
  # email - Logined user's email address.
  # accessId - Access id.
  # userId - Logined user's id.
  # spaceAmount - The storage's free space.
  # spaceUsed - The storage's used space.
  class UserStorageInfo
    attr_accessor :authToken, :loginName, :email, :accessId, :userId, :spaceAmount,
    :spaceUsed

    # Constructor.
    #
    def initialize(userStorageElement)
      @authToken = nil
      createUserStorageInfo(userStorageElement) if (userStorageElement != nil)
    end

    private
    def createUserStorageInfo(userStorageElement)
      @loginName = userStorageElement.elements['login'].text
      @email = userStorageElement.elements['email'].text
      @accessId = userStorageElement.elements['access_id'].text
      @userId = userStorageElement.elements['user_id'].text.to_i
      @spaceAmount = userStorageElement.elements['space_amount'].text.to_i
      @spaceUsed = userStorageElement.elements['space_used'].text.to_i
    end
  end

  #Tag information class.
  #
  #attributes:
  # tagId - Tag id.
  # description - Tag's description.
  class TagInfo
    attr_accessor :tagId, :description

    # Constructor.
    #
    def initialize(tagElement)
      createTagInfo(tagElement)
    end

    private
    def createTagInfo(tagElement)
      @tagId = tagElement.attributes['id'].to_i
      @description = tagElement.text
    end
  end

  #Folder information class.
  #
  #attributes:
  # userId - Logined user's id.
  # folderId - The folder id.
  # folderName - The folder name.
  # description - The folder's description.
  # createDate - The folder's created date.
  # updateDate - The folder's update date.
  # totalFileSize - Total size of the folder's files.
  # shared - Shared flag(0 = unshare, 1 = share).
  # sharedLinkName - The folder's shared(public) name.
  # permissions - The folder's permissions.
  # fileList - Files list.
  # childFolderList - Child folder list.
  # numOfTags - Number of tags folder has.
  # tagList - Tag list.
  class FolderInfo
    attr_accessor :userId, :folderId, :folderName, :description, :createDate, :updateDate,
    :totalFolderSize, :shared, :sharedLinkName, :permissions, :fileList,
    :childFolderList, :numOfTags, :tagList

    # Constructor.
    #
    def initialize(folderElement)
      createFolderInfo(folderElement) if (folderElement != nil)
    end

    private
    def createFolderInfo(folderElement)
      @userId = folderElement.attributes['user_id'].to_i
      @folderId = folderElement.attributes['id'].to_i
      @folderName = folderElement.attributes['name']
      @description = folderElement.attributes['description']
      @createDate = folderElement.attributes['created'].to_i
      @updateDate = folderElement.attributes['updated'].to_i
      @totalFolderSize = folderElement.attributes['size'].to_i
      @shared = folderElement.attributes['shared'].to_i
      @sharedLinkName = folderElement.attributes['shared_link']
      @permissions = folderElement.attributes['permissions']

      if (folderElement.elements['files'] != nil)
        @fileList = Array.new
        folderElement.elements.each('files/file') do |fileElement|
          @fileList.push(FileInFolderInfo.new(fileElement))
        end
      else
        @fileList = nil
      end

      if (folderElement.elements['folders'] != nil)
        @childFolderList = Array.new
        folderElement.elements.each('folders/folder') do |childFolderElement|
          @childFolderList.push(FolderInfo.new(childFolderElement))
        end
      else
        @childFolderList = nil
      end

      if (folderElement.elements['tags'] != nil)
        @tagList = Array.new
        folderElement.elements.each('/tags/tag') do |tagElement|
          @tagList.push(BoxNetClientLib::TagInfo.new(tagElement))
        end
      end
    end
  end

  #File information class in the Folder.
  #
  # userId - Logined user's id.
  # fileId - File id.
  # fileName - File name.
  # description - File description.
  # sha1 - File's hash value.
  # createDate - File create date.
  # updateDate - File update date.
  # size - File size.
  # shared - Share flag(0 = unshare, 1 = share).
  # sharedLinkName - The file's shared(public) name.
  # thumbNail - The file's thumbnail URI.
  # smallThumbNail - The file's small thumbnail URI.
  # largeThumbNail - The file's large thumbnail URI.
  # largerThumbNail - The file's larger thumbail URI.
  # previewThumbNail - The file's preview thumbnail URI.
  # permissions - Permissions.
  # numOfTags - Number of tags the file has.
  # tagList - Tag list.
  class FileInFolderInfo
    attr_accessor :userId, :fileId, :fileName, :description, :sha1, :createDate,
    :updateDate, :size, :shared, :sharedLinkName, :thumbNail, :smallThumbNail,
    :largeThumbNail, :largerThumbNail, :previewThumbNail, :permissions,
    :tagList

    # Constructor.
    #
    def initialize(fileElement)
      createFileInfoByAttributes(fileElement) if (fileElement != nil)
    end

    private
    def createFileInfoByAttributes(fileElement)
      @userId = fileElement.attributes['user_id'].to_i
      @fileId = fileElement.attributes['id'].to_i
      @fileName = fileElement.attributes['file_name']
      @description = fileElement.attributes['description']
      @sha1 = fileElement.attributes['sha1']
      @createDate = fileElement.attributes['created'].to_i
      @updateDate = fileElement.attributes['updated'].to_i
      @size = fileElement.attributes['size'].to_i
      @shared = fileElement.attributes['shared'].to_i
      @sharedLinkName = fileElement.attributes['shared_link']
      @thumbNail = fileElement.attributes['thumbnail']
      @smallThumbNail = fileElement.attributes['small_thumbnail']
      @largeThumbNail = fileElement.attributes['large_thumbnail']
      @largerThumbNail = fileElement.attributes['larger_thumbnail']
      @previewThumbNail = fileElement.attributes['preview_thumbnail']
      @permissions = fileElement.attributes['permissions']

      if (fileElement.elements['tags'] != nil)
        @tagList = Array.new
        fileElement.elements.each('/tags/tag') do |tagElement|
          @tagList.push(TagInfo.new(tagElement))
        end
      end
    end
  end

  #File information class.
  #
  # userId - Logined user's id.
  # fileId - File id.
  # fileName - File name.
  # parentFolderId - Parent folder id.
  # description - File description.
  # sha1 - File's hash value.
  # createDate - File create date.
  # updateDate - File update date.
  # size - File size.
  # shared - Share flag(0 = unshare, 1 = share).
  # sharedLinkName - The file's shared(public) name.
  class FileInfo
    attr_accessor :userId, :fileId, :fileName, :parentFolderId, :description, :sha1, :createDate,
    :updateDate, :size, :shared, :sharedLinkName

    # Constructor.
    #
    def initialize(fileElement)
      createFileInfo(fileElement) if (fileElement != nil)
    end

    private
    def createFileInfo(fileElement)
      @fileId = fileElement.elements['file_id'].text.to_i
      @fileName = fileElement.elements['file_name'].text
      @parentFolderId = fileElement.elements['folder_id'].text.to_i
      @description = fileElement.elements['description'].text
      @sha1 = fileElement.elements['sha1'].text
      @createDate = fileElement.elements['created'].text.to_i
      @updateDate = fileElement.elements['updated'].text.to_i
      @size = fileElement.elements['size'].text.to_i
      @shared = fileElement.elements['shared'].text.to_i
      @sharedLinkName = fileElement.elements['shared_name'].text
    end
  end

  #Created folder information class.
  #
  #attributes:
  # userId - Logined user's id.
  # folderId - The folder id.
  # folderName - The folder name.
  # folderPath - The folder's path.
  # shared - Shared flag(0 = unshare, 1 = share).
  # sharedLinkName - The folder's shared(public) name.
  # parentFolderId - Parent folder id.
  # password - Password to open the folder.
  class CreatedFolderInfo
    attr_accessor :userId, :folderId, :folderName, :folderPath, :shared, :sharedLinkName,
    :parentFolderId, :password

    # Constructor.
    #
    def initialize(folderElement)
      createCreatedFolderInfo(folderElement) if (folderElement != nil)
    end

    private
    def createCreatedFolderInfo(folderElement)
      @userId = folderElement.elements['user_id'].text.to_i
      @folderId = folderElement.elements['folder_id'].text.to_i
      @folderName = folderElement.elements['folder_name'].text
      @folderPath = folderElement.elements['path'].text
      @shared = folderElement.elements['shared'].text.to_i
      @sharedLinkName = folderElement.elements['public_name'].text
      @parentFolderId = folderElement.elements['parent_folder_id'].text.to_i
      @password = folderElement.elements['password'].text
    end
  end

  #Friend information class.
  #
  #attributes:
  # friendName - The friend's name.
  # email - The friend's email address.
  # accepted - Allow or deny to access the friend's box.
  # avatarURL - The friend's avatar URL.
  # boxList - Box list.
  class FriendInfo
    attr_accessor :friendName, :email, :accepted, :avatarURL, :boxList

    # Constructor.
    #
    def initialize(friendElement)
      createFriendInfo(friendElement) if (friendElement != nil)
    end

    private
    def createFriendInfo(friendElement)
      @friendName = friendElement.elements['name'].text
      @email = friendElement.elements['email'].text
      @accepted = friendElement.elements['accepted'].text
      @avatarURL = friendElement.elements['avatar_url'].text
      @boxList = Array.new
      fileElement.elements.each('/boxes/box') do |boxElement|
        @boxList.push(BoxInfo.new(boxElement))
      end
    end
  end

  #Box information class.
  #
  #attributes:
  # boxId - The box id.
  # URL - The box URL.
  class BoxInfo
    attr_accessor :boxId, :URL

    # Constructor.
    #
    def initialize(boxElement)
      createBoxList(boxElement) if (boxElement != nil)
    end

    private
    def createBoxList(boxElement)
      @boxId = boxElement.elements['id']
      @URL = boxElement.elements['url']
    end
  end
  #Uploaded file information class.
  #
  #attributes:
  # fileName - The uploaded file name.
  # fileId - The uploaded file id.
  # parentFolderId - The uploaded file's parent folder id.
  # publicName - The uploaded file's public name.
  # status - "upload_ok":File upload is success.
  #          others     :File upload occues something error(ex. filesize_limit_exceeded).
  class UploadedFileInfo
    attr_accessor :fileName, :fileId, :parentFolderId, :shared, :publicName, :status

    # Constructor.
    #
    def initialize(fileElement)
      createUploadedFileInfo(fileElement) if (fileElement != nil)
    end

    private
    def createUploadedFileInfo(fileElement)
      @fileName = fileElement.attributes['file_name']
      if (fileElement.attributes['error'] != nil)
        @status = fileElement.attributes['error']
      else
        @status = "upload_ok"
        @fileId =  fileElement.attributes['id']
        @parentFolderId = fileElement.attributes['folder_id']
        @shared = fileElement.attributes['shared']
        @publicName = fileElement.attributes['public_name']
      end
    end
  end
end
