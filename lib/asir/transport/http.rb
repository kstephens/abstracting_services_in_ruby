require 'asir'

require 'rubygems'
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

      CONTENT_TYPE = 'Content-Type'.freeze
      APPLICATION_BINARY = 'application/binary'.freeze

      # Client-side: HTTPClient

      def client 
        @client ||= 
          Channel.new(:on_connect => 
            lambda { | channel | ::HTTPClient.new })
      end

      def close
        @client.close if @client
      ensure
        @client = nil unless Channel === @client
      end

      # Send the Request payload String using HTTP POST.
      # Returns the HTTPClient::Message response object.
      def _send_request request, request_payload
        client.with_stream! do | client |
        client.post(uri, request_payload)
        end
      end

      # Recieve the Response payload String from the opaque
      # HTTPClient::Message response object returned from #_send_request.
      def _receive_response http_response_message
        http_response_message.content.to_s
      end

      # Server-side: WEBrick
 
      # Receive the Request payload String from the HTTP Request object.
      # Returns the original http_request as the request_state.
      def _receive_request http_request, additional_data
        [ http_request.body, http_request ]
      end
      
      # Send the Response payload String in the HTTP Response object as application/binary.
      def _send_response response, response_payload, http_response, request_state
        http_response[CONTENT_TYPE] = APPLICATION_BINARY
        http_response.body = response_payload
      end

      def setup_webrick_server! opts = { }
        require 'webrick'
        u = URI.parse(uri)
        port = u.port
        path = u.path
        opts[:Port] ||= port
        @server = WEBrick::HTTPServer.new(opts)
        @server.mount_proc path, lambda { | rq, rs |
          serve_request! rq, rs
        }
        self
      rescue Exception => exc
        raise Error, "Webrick Server #{uri.inspect}: #{exc.inspect}", exc.backtrace
      end

      def start_webrick_server!
        @server.start
        self
      end

    end # class
  end # class
end # module 

