require 'box/api'
require 'box/folder'

module Box
  class Account
    attr_reader :api, :ticket, :auth_token

    # setup the api using our api_key
    def initialize(api)
      @api = case
        when api.class == Box::Api; api # use the api object as passed in
        else; Box::Api.new(api) # allows user to pass in the api_key rather than make a new API object themselves
      end
    end

    #### AUTHENTICATION SECTION ####
    # register the user with the given details
    def register(email, password)
      # note: this function can throw EmailInvalid and EmailTaken
      response = @api.register_new_user(email, password)

      cache_info(response['user']) # cache account_info, saves an extra API call
      authorize_token(response['token'])
    end

    # logout, rendering any auth_token useless
    def logout
      begin
        @api.logout
        authorize_token(nil)
      rescue Api::NotAuthorized
        # already logged out, or never logged in
      end

      true
    end

    # authorize the application either using a saved auth_token or ask for a new token
    def authorize(auth_token = self.auth_token)
      return true if auth_token and authorize_token(auth_token) # saved auth_tokens significantly speed up the authentication process

      if block_given? and not authorize_ticket # if we cannot authorize the ticket, the user needs to visit a web page and give our app permission
        yield authorize_url # the supplied block should instruct the user to visit this url, returning once they have
        authorize_ticket # try authorizing again, assuming the user has authed now
      end

      authorized?
    end

    # tickets are used to associate authentication attempts, so each user needs their own ticket
    def ticket
      @ticket ||= @api.get_ticket['ticket']
    end

    # the user must visit this url to allow the application to access their account
    def authorize_url(ticket = self.ticket)
      "#{ api.base_url }/auth/#{ ticket }"
    end

    # using the ticket, we get the auth_token providing the user has already allowed our application the privilege
    def authorize_ticket(ticket = self.ticket) # note: self.ticket will request a ticket if none exists, not the same as @ticket
      begin
        response = @api.get_auth_token(ticket)

        cache_info(response['user']) # cache account_info, saves an extra API call
        authorize_token(response['auth_token'])
      rescue Api::NotAuthorized
        false
      end
    end

    # we have a token, and we have to save it and check if it is valid
    def authorize_token(auth_token = self.auth_token)
      @api.set_auth_token(auth_token)
      @auth_token = auth_token if authorized? # set auth token if successful
    end

    # we are authorized if we have the user's account info
    def authorized?
      info != nil
    end

    # return the cached account info, or request it
    def info
      return @info if @info

      begin
        info = @api.get_account_info['user']
        cache_info(info)
      rescue Api::NotAuthorized, Api::InvalidInput
        nil
      end
    end

    # return the root of the user's folder structure
    def root
      return @root if @root
      @root = Box::Folder.new(@api, nil, :id => 0)
    end

    protected

    # cache account info, possibly from get_auth_token, register_new_user, or get_account_info
    def cache_info(info)
      @info = info
    end
  end
end
