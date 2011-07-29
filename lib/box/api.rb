require 'box/api/exceptions'

require 'httmultiparty'

module Box
  class Api
    include HTTMultiParty # a slight modification to HTTParty, adding multi-part upload support

    attr_accessor :base_url, :upload_url

    def initialize(key, url = 'https://box.net', upload_url = 'https://upload.box.net', version = '1.0')
      @default_params = { :api_key => key } # add the api_key to every query

      @base_url = "#{ url }/api/#{ version }" # set the base of the request url
      @upload_url = "#{ upload_url }/api/#{ version }" # uploads use a different url than everything else
    end

    def query_rest(expected, options = {})
      query_raw('get', "#{ @base_url }/rest", expected, options)['response']
    end

    def query_download(query, args, options = {})
      url = [ "#{ @base_url }/#{ query }", @auth_token, args ].flatten.compact.join('/') # /download/<auth_token>/<arg1>/<arg2>/<etc>
      query_raw('get', url, nil, options) # note, expected is nil because the return will be raw data
    end

    def query_upload(query, args, expected, options = {})
      url = [ "#{ @upload_url }/#{ query }", @auth_token, args ].flatten.compact.join('/') # /upload/<auth_token>/<arg1>/<arg2>/<etc>
      query_raw('post', url, expected, options)['response']
    end

    def query_raw(method, url, expected, options = {})
      response = case method
      when 'get'
        self.class.get(url, :query => @default_params.merge(options))
      when 'post'
        self.class.post(url, :query => @default_params.merge(options), :format => :xml) # known bug with api that only occurs with uploads, will be fixed soon
      end

      handle_response(response, expected)
    end

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

    def get_ticket
      query_rest('get_ticket_ok', :action => :get_ticket)
    end

    def get_auth_token(ticket)
      query_rest('get_auth_token_ok', :action => :get_auth_token, :ticket => ticket)
    end

    # save the auth token and add it to every request
    def set_auth_token(auth_token)
      @auth_token = auth_token
      @default_params[:auth_token] = auth_token
    end

    def logout
      query_rest('logout_ok', :action => :logout)
    end

    def register_new_user(login, password)
      query_rest('successful_register', :action => :register_new_user, :login => login, :password => password)
    end

    def verify_registration_email(login)
      query_rest('email_ok', :action => :verify_registration_email, :login => login)
    end

    def get_account_info
      query_rest('get_account_info_ok', :action => :get_account_info)
    end

    # TODO: Use zip compression to save space
    def get_account_tree(folder_id = 0, *args)
      query_rest('listing_ok', :action => :get_account_tree, :folder_id => folder_id, :params => [ 'nozip' ] + args)
    end

    def create_folder(parent_id, name, share = 0)
      query_rest('create_ok', :action => :create_folder, :parent_id => parent_id, :name => name, :share => share)
    end

    def move(target, target_id, destination_id)
      query_rest('s_move_node', :action => :move, :target => target, :target_id => target_id, :destination_id => destination_id)
    end

    def copy(target, target_id, destination_id)
      query_rest('s_copy_node', :action => :copy, :target => target, :target_id => target_id, :destination_id => destination_id)
    end

    def rename(target, target_id, new_name)
      query_rest('s_rename_node', :action => :rename, :target => target, :target_id => target_id, :new_name => new_name)
    end

    def delete(target, target_id)
      query_rest('s_delete_node', :action => :delete, :target => target, :target_id => target_id)
    end

    def get_file_info(file_id)
      query_rest('s_get_file_info', :action => :get_file_info, :file_id => file_id)
    end

    def set_description(target, target_id, description)
      query_rest('s_set_description', :action => :set_description, :target => target, :target_id => target_id, :description => description)
    end

    def download(path, file_id, version = nil)
      ::File.open(path, 'w') do |file|
        file << query_download('download', [ file_id, version ]) # write the response directly to file
      end
    end

    def upload(path, folder_id, new_copy = false)
      query_upload('upload', folder_id, 'upload_ok', :file => ::File.new(path), :new_copy => new_copy)
    end

    def overwrite(path, file_id, name = nil)
      query_upload('overwrite', file_id, 'upload_ok', :file => ::File.new(path), :file_name => name)
    end

    def new_copy(path, file_id, name = nil)
      query_upload('new_copy', file_id, 'upload_ok', :file => ::File.new(path), :new_file_name => name)
    end
  end
end
