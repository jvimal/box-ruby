require 'box/api/exceptions'

require 'httmultiparty'

module Box
  # A wrapper and interface to the Box api. Please visit the Box developers
  # site for a full explaination of what each of the Box api methods
  # expect and perform.
  # TODO: Link to the site.

  class Api
    # an extension of HTTParty, adding multi-part upload support
    include HTTMultiParty

    attr_accessor :base_url, :upload_url

    # Create a new API object using the given parameters.
    #
    # @note Chances are that if the Box api is updated or moves location,
    #       this class will no longer work. However, the option to change
    #       the defaults still remains.
    #
    # @param [String, Api] api_key The api key for your application. You can
    #        request one on the Box developer website at
    #        {http://www.box.net/developers/services}. If an {Api} instance
    #        is passed instead, its key is used.
    #
    # @param [String] url the url of the Box api.
    # @param [String] upload_url the url of the upload host for the Box api.
    # @param [String] version the version of the Box api in use.
    #
    def initialize(key, url = 'https://box.net', upload_url = 'https://upload.box.net', version = '1.0')
      @default_params = { :api_key => key } # add the api_key to every query

      @base_url = "#{ url }/api/#{ version }" # set the base of the request url
      @upload_url = "#{ upload_url }/api/#{ version }" # uploads use a different url than everything else
    end

    # Make a normal REST request.
    #
    # @param [String] expected the normal status expected to be returned.
    #        If the actual status does not match, an exception is thrown.
    # @param [Hash] options The parameters that wish to be passed in the
    #        request. These should coorespond to the api specifications,
    #        and will be passed along with the api key and auth token.
    #
    # @return [Hash] A parsed version of the XML response.
    #
    def query_rest(expected, options = {})
      query_raw('get', "#{ @base_url }/rest", expected, options)['response']
    end

    # Make a download request.
    #
    # @param [String] query the operation to be performed ("download").
    # @param [Array] args an array of arguments to put in the url.
    # @param [Hash] options (see #query_rest)
    #
    # @return The raw binary data of the file.
    #
    # TODO: query is not needed, should be set to "download"
    def query_download(query, args, options = {})
      # produces: /download/<auth_token>/<arg1>/<arg2>/<etc>
      url = [ "#{ @base_url }/#{ query }", @auth_token, args ].flatten.compact.join('/')
      query_raw('get', url, nil, options)
    end

    # Make an upload request.
    #
    # @param [String] query The operation to be performed.
    # @param [Array] args (see #query_download)
    # @param [String] expected (see #query_rest)
    # @param [Hash] options (see #query_rest)
    #
    # @return (see #query_rest)
    #
    def query_upload(query, args, expected, options = {})
      # produces: /upload/<auth_token>/<arg1>/<arg2>/<etc>
      url = [ "#{ @upload_url }/#{ query }", @auth_token, args ].flatten.compact.join('/')
      query_raw('post', url, expected, options)['response']
    end

    # Make a raw request.
    #
    # @note: HTTParty will automatically parse the response from its native
    #        XML to a nested hash/array structure.
    #
    # @param ['get', 'post'] method The HTTP method to use.
    # @param [String] url The url to make the request.
    # @param [String] expected (see #query_rest)
    # @param [Hash] options (see #query_rest)
    #
    # @return (see #query_rest)
    #
    def query_raw(method, url, expected, options = {})
      response = case method
      when 'get'
        self.class.get(url, :query => @default_params.merge(options))
      when 'post'
        self.class.post(url, :query => @default_params.merge(options), :format => :xml) # known bug with api that only occurs with uploads, will be fixed soon
      end

      handle_response(response, expected)
    end

    # Handle the response of the request.
    #
    # @param [Hash] response The parsed representation of the XML response.
    # @param expected (see #query_rest)
    #
    # @return [Hash] The response if no errors were found.
    # @raise [Exception, UnknownResponse] Raises an exception if the
    #        response status does not match the expected. This exception
    #        is determined by {.get_exception}
    def handle_response(response, expected = nil)
      if expected
        begin
          status = response['response']['status']
        rescue
          raise UnknownResponse, "Unknown response: #{ response }"
        end

        unless status == expected # expected is the normal, successful status for this request
          exception = self.class.get_exception(status)
          raise exception, status
        end
      end

      raise ErrorStatus, response.code unless response.success? # when the http return code is not normal
      response
    end

    # TODO: Add link to API documentation for all functions below.
    # TODO: Document exceptions that could be thrown.

    # Request a ticket for authorization
    def get_ticket
      query_rest('get_ticket_ok', :action => :get_ticket)
    end

    # Request an auth token given a ticket.
    #
    # @param [String] ticket the ticket to use.
    def get_auth_token(ticket)
      query_rest('get_auth_token_ok', :action => :get_auth_token, :ticket => ticket)
    end

    # Add the auth token to every request.
    #
    # @param [String] auth_token The auth token to add to every request.
    def set_auth_token(auth_token)
      @auth_token = auth_token
      @default_params[:auth_token] = auth_token
    end

    # Request the user be logged out.
    def logout
      query_rest('logout_ok', :action => :logout)
    end

    # Register a new user.
    #
    # @param [String] email The email address to use.
    # @param [String] password The password to use.
    def register_new_user(email, password)
      query_rest('successful_register', :action => :register_new_user, :login => email, :password => password)
    end

    # Verify a registration email.
    #
    # @param [String] email The email address to check.
    def verify_registration_email(email)
      query_rest('email_ok', :action => :verify_registration_email, :login => email)
    end

    # Get the user's account info.
    def get_account_info
      query_rest('get_account_info_ok', :action => :get_account_info)
    end

    # Get the entire tree of a given folder.
    #
    # @param [String] folder_id The id of the folder to use.
    # @param [Array] args The arguments to pass along to get_account_tree.
    #
    # @note This function can take a long time for large folders.
    # @todo Use zip compression to save bandwidth.
    #
    # TODO: document the possible arguments.
    def get_account_tree(folder_id, *args)
      query_rest('listing_ok', :action => :get_account_tree, :folder_id => folder_id, :params => [ 'nozip' ] + args)
    end

    # Create a new folder.
    #
    # @param [String] parent_id The id of the parent folder to use.
    # @param [String] name The name of the newly created folder.
    # @param [Integer] shared The shared state of the new folder.
    def create_folder(parent_id, name, share = 0)
      query_rest('create_ok', :action => :create_folder, :parent_id => parent_id, :name => name, :share => share)
    end

    # Move the item to a new destination.
    #
    # @param ["file", "folder"] target The type of item.
    # @param [String] target_id The id of the item to move.
    # @param [String] destination_id The id of the parent to move to.
    def move(target, target_id, destination_id)
      query_rest('s_move_node', :action => :move, :target => target, :target_id => target_id, :destination_id => destination_id)
    end

    # Copy the the item to a new destination.
    #
    # @note The api currently only supports copying files.
    #
    # @param ["file"] target The type of item.
    # @param [String] target_id The id of the item to copy.
    # @param [String] destination_id The id of the parent to copy to.
    def copy(target, target_id, destination_id)
      query_rest('s_copy_node', :action => :copy, :target => target, :target_id => target_id, :destination_id => destination_id)
    end

    # Rename the item.
    #
    # @param ["file", "folder"] target The type of item.
    # @param [String] target_id The id of the item to rename.
    # @param [String] new_name The new name to be used.
    def rename(target, target_id, new_name)
      query_rest('s_rename_node', :action => :rename, :target => target, :target_id => target_id, :new_name => new_name)
    end

    # Delete the item.
    #
    # @param ["file", "folder"] target The type of item.
    # @param [String] target_id The id of the item to delete.
    def delete(target, target_id)
      query_rest('s_delete_node', :action => :delete, :target => target, :target_id => target_id)
    end

    # Get the file info.
    #
    # @param [String] file_id The file id to get info for.
    def get_file_info(file_id)
      query_rest('s_get_file_info', :action => :get_file_info, :file_id => file_id)
    end

    # Set the item description.
    #
    # @param ["file", "folder"] target The type of item.
    # @param [String] target_id The id of the item to describe.
    # @param [String] description The description to use.
    def set_description(target, target_id, description)
      query_rest('s_set_description', :action => :set_description, :target => target, :target_id => target_id, :description => description)
    end

    # Download the file to the given path.
    #
    # @note You cannot download folders.
    #
    # @param [String] path The path to write the file to.
    # @param [String] file_id The file id to download.
    # @param [Optional, String] version The version of the file to download.
    def download(path, file_id, version = nil)
      ::File.open(path, 'w') do |file|
        file << query_download('download', [ file_id, version ]) # write the response directly to file
      end
    end

    # Upload the file to the specified folder.
    #
    # @param [String] path Upload the file at the given path.
    # @param [String] folder_id The folder id of the parent folder to use.
    # @param [Optional, Boolean] new_copy Upload a new copy instead of overwriting.
    def upload(path, folder_id, new_copy = false)
      query_upload('upload', folder_id, 'upload_ok', :file => ::File.new(path), :new_copy => new_copy)
    end

    # Overwrite the given file with a new one.
    #
    # @param [String] path (see #upload)
    # @param [String] file_id Replace the file with this id.
    # @param [Optional, String] name Use a new name as well.
    def overwrite(path, file_id, name = nil)
      query_upload('overwrite', file_id, 'upload_ok', :file => ::File.new(path), :file_name => name)
    end

    # Upload a new copy of the given file.
    #
    # @param [String] path (see #upload)
    # @param [String] file_id The id of the file to copy.
    # @param [Optional, String] name Use a new name as well.
    # TODO: Verfiy this does what I think it does
    def new_copy(path, file_id, name = nil)
      query_upload('new_copy', file_id, 'upload_ok', :file => ::File.new(path), :new_file_name => name)
    end
  end
end
