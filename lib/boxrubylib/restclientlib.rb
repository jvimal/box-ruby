#= restclientlib.rb
#Author:: Takehiko Watanabe
#CopyRights:: Canon Software Inc.
#Created date:: 2009/06/10
#Last Modified:: 2009/11/09
#Version:: 1.0.1
#
#This file contains RestClientLib module.

require "net/http"
require "net/https"
require "openssl"
require "rexml/document"
require "digest/md5"
require "cgi"
Net::HTTP.version_1_2
#
#= module of Rest Client Library
#
module RestClientLib

  #Http client class.
  #
  #attributes:
  # proxyUrl - Proxy server URL, if you don't want to use Proxy set nil.
  # proxyPort - Proxy server port.
  class HttpClient
    attr_accessor :proxyUrl, :proxyPort, :useSSL

    # Constructor.
    #
    def initialize
      @proxyUrl = nil
      @proxyPort = nil
      @useSSL = false
    end

    # Throw http get request method to the server.
    #
    #  [server]
    #   Server address.
    #  [port]
    #   Server port. If you want to use default port 80, you pass the parameter - nil.
    #  [uri]
    #   URI(include parameter and value).
    #  [header]
    #   HTTP header. If you don't need to describe, you pass the parameter - nil.
    #
    #  [Return value]
    #   Http response body.
    def httpGetRequest(server, port, uri, header)
      port = 80 if (port == nil)
      h = Net::HTTP::Proxy(@proxyUrl,@proxyPort).new(server, port)
      if (@useSSL == true)
        h.use_ssl = true
        h.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      return h.start() { |http|
        response = http.get(uri, header)
        response.body
      }
    end

    # Throw http post request method to the server.
    #
    #  [server]
    #   Server address.
    #  [port]
    #   Server port. If you want to use default port 80, you pass the parameter - nil.
    #  [uri]
    #   URI.
    #  [header]
    #   HTTP header. If you don't need to describe, you pass the parameter - nil.
    #  [data]
    #   HTTP query data.
    #
    #  [Return value]
    #   Http response body.
    def httpPostRequest(server, port, uri, header, data)
      port = 80 if (port == nil)
      h = Net::HTTP::Proxy(@proxyUrl,@proxyPort).new(server, port)
      if (@useSSL == true)
        h.use_ssl = true
        h.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      return h.start() { |http|
        response = http.post(uri, data, header)
        response.body
      }

    end

    # Generate query string.
    #
    #  [params]
    #   Query parameter. You need to pass this parameter to hash type.
    #
    #  [Return value]
    #   Http response body.
    def genQueryString(params)
      ret = Array.new
      params.each do |k,l|
        if l.kind_of?(Array)
          l.each do |m|
            ret.push(CGI::escape(k.to_s) + "=" + CGI::escape(m.to_s))
          end
        else
          ret.push(CGI::escape(k.to_s) + "=" + CGI::escape(l.to_s))
        end
      end
      ret.join("&")
    end

    # Determine MIME type from file name.
    #
    #  [filename]
    #   File name.
    #
    #  [Return value]
    #   MIME type.
    def resolveMime(filename)
      if filename =~ /\.(\w+)$/
        extn = $1
        case extn
          when "form"   then return "multipart/form-data"
          when "txt"    then return "text/plain"
          when "html"   then return "text/html"
          when "htm"    then return "text/html"
          when "jpg"    then return "image/jpeg"
          when "png"    then return "image/png"
          when "gif"    then return "image/gif"
        else         return "application/octet-stream"
        end
      else
        return "application/octet-stream"
      end
    end

    # Assemble to multipart query.
    #
    #  [name]
    #   Parameter name.
    #  [value]
    #   Parameter value.
    #
    #  [Return value]
    #   Multipart query.
    def toMultiPart(name, value)
      return "Content-Disposition: form-data; name=\"#{CGI::escape(name)}\"\n\n#{value.to_s}\n"
    end

    # File to multipart query.
    #
    #  [filename]
    #   File name.
    #  [content]
    #   File contents.
    #
    #  [Return value]
    #   File query.
    def fileToMultiPart(filename, content)
      mimetype = resolveMime(filename)
      ret = "Content-Disposition: form-data; name=\"fileField\"; filename=\"#{filename}\"\n"
      if (mimetype != nil)
        ret += "Content-Type: #{mimetype}\n\n" + content + "\n"
      end
      return ret
    end

    # Generate query for post method.
    #
    #  [filename]
    #   File name.
    #  [params]
    #   Parameters.
    #  [data]
    #   File data.
    #  [boundary]
    #   Query boundary.
    #
    #  [Return value]
    #   Query string.
    def prepareQuery(filename, params, data, boundary)
      query = ""
      if (params != nil)
        params.each do |key, value|
          if (defined?(value)&&(value.instance_of?(Array)))
            value.each do |item|
              query += "--" + boundary +"\n" + toMultiPart(key, item)
            end
          else
            query += "--" + boundary + "\n" + toMultiPart(key, value)
          end
        end
      end
      if ((filename != nil)&&(data != nil))
        query += "--" + boundary + "\n"
        query += fileToMultiPart(filename, data)
      end
      query += "--" + boundary + "--\n" if (query != nil)

      return query
    end
  end

  #Rest client class.
  #
  class RestClient < HttpClient
    # Constructor.
    #
    def initialize
      super
    end

    # Throw rest get request method to the server.
    #
    #  [server]
    #   Server address.
    #  [port]
    #   Server port. If you want to use default port 80, you pass the parameter - nil.
    #  [apipath]
    #   Api path to rest request.
    #  [params]
    #    Parameters to get. You need to pass this parameter to hash type.
    #  [header]
    #   HTTP header.  If you don't need to describe, you pass the parameter - nil.
    #
    #  [Return value]
    #   Xml document.
    def getRequest(server, port, apipath, params, header)
      if (params != nil)
        uri = apipath + "?" + genQueryString(params)
      else
        uri = apipath
      end
      body = self.httpGetRequest(server, port, uri, header)
      begin
        return REXML::Document.new(body) if body
        return nil
      rescue
        body
      end
    end

    # Throw rest post request method to the server.
    # Notice - This method makes content-type header field automatically,
    #          so you don't set content-type to "header" parameter.
    #
    #  [server]
    #   Server address.
    #  [port]
    #   Server port. If you want to use default port 80, you pass the parameter - nil.
    #  [apipath]
    #   Api path to rest request.
    #  [fileName]
    #   File name, if you want to post file.
    #  [data]
    #   File data, if you want to post file.
    #  [params]
    #    Parameters to post. You need to pass this parameter to hash type.
    #  [header]
    #   HTTP header.  If you don't need to describe, you pass the parameter - nil.
    #
    #  [Return value]
    #   Xml document.
    def postRequest(server, port, apipath, fileName, data, params, header)
      boundary = Digest::MD5.hexdigest(fileName != nil ? fileName : Time.now.to_s).to_s
      query = self.prepareQuery(fileName, params, data, boundary)
      if (header != nil)
        localheader = Hash[header]
      else
        localheader = Hash.new
      end
      localheader['Content-Type'] = "multipart/form-data, boundary=" + boundary + "\r\n"
      localheader['Content-Length'] = query.length.to_s
      body = self.httpPostRequest(server, port, apipath, localheader, query)
      begin
        return REXML::Document.new(body) if body
        return nil
      rescue
        return body
      end
    end
  end
end