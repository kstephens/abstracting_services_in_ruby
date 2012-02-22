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

      # Send the Message payload String using HTTP POST.
      # Returns the HTTPClient::Request response object.
      def _send_message message, message_payload
        client.with_stream! do | client |
          client.post(uri, message_payload)
        end
      end

      # Recieve the Result payload String from the opaque
      # HTTPClient::Request response object returned from #_send_message.
      def _receive_result message, http_result_message
        http_result_message.content.to_s
      end

      # Server-side: WEBrick

      # Receive the Message payload String from the HTTP Message object.
      # Returns the original http_message as the message_state.
      def _receive_message http_message, additional_data
        [ http_message.body, http_message ]
      end

      # Send the Result payload String in the HTTP Response object as application/binary.
      def _send_result message, result, result_payload, http_result, message_state
        http_result[CONTENT_TYPE] = APPLICATION_BINARY
        http_result.body = result_payload
      end

      # TODO: rename prepare_webrick_server!
      def setup_webrick_server! opts = { }
        require 'webrick'
        u = URI.parse(uri)
        port = u.port
        path = u.path
        opts[:Port] ||= port
        @server = ::WEBrick::HTTPServer.new(opts)
        @server.mount_proc path, lambda { | rq, rs |
          serve_message! rq, rs
        }
        self
      rescue ::Exception => exc
        raise Error, "Webrick Server #{uri.inspect}: #{exc.inspect}", exc.backtrace
      end

      # TODO: rename run_webrick_server!
      def start_webrick_server!
        @server.start
        self
      end

    end # class

    # Webrick transport.
    class Webrick < HTTP
      alias :prepare_server! :setup_webrick_server!
      alias :run_server! :start_webrick_server!
    end

  end # class
end # module 

