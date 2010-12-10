require 'asir'

require 'rubygems'
require 'webrick'
gem 'httpclient'
require 'httpclient'
require 'uri'

module ASIR
  class Transport
    # !SLIDE
    # HTTP Transport
    #
    # Using HTTPClient and WEBrick.
    class HTTP < self
      attr_accessor :uri, :server, :debug

      # Client-side: HTTPClient

      # Send the Request payload String using HTTP POST.
      # Returns the HTTPClient::Message response object.
      def _send_request request_payload
        client = ::HTTPClient.new
        client.post(uri, request_payload)
      end

      # Recieve the Response payload String from the opaque
      # HTTPClient::Message response object returned from #_send_request.
      def _receive_response http_response_message
        http_response_message.content.to_s
      end

      # Server-side: WEBrick
 
      # Receive the Request payload String from the WEBrick Request object.
      def _receive_request webrick_request
        webrick_request.body
      end

      # Send the Response payload String in the WEBrick Response object.
      def _send_response result, webrick_response
        webrick_response['Content-Type'] = 'application/binary'
        webrick_response.body = result
      end

      def setup_webrick_server!
        u = URI.parse(uri)
        port = u.port
        path = u.path
        @server = WEBrick::HTTPServer.new(:Port => port)
        @server.mount_proc path, lambda { | rq, rs |      
          serve_request! rq, rs
        }
        self
      end

      def start_webbrick_server!
        @server.start
        self
      end

    end # class
  end # class
end # module 

