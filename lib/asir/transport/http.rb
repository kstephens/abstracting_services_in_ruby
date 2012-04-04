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
    # Using HTTPClient.
    class HTTP < self
      attr_accessor :uri, :server, :debug

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
        $stderr.puts " ### http_result_message.content.encoding = #{http_result_message.content.encoding.inspect}" rescue nil
        $stderr.puts " ### http_result_message.content = #{http_result_message.content.inspect}" rescue nil
        http_result_message.content.to_s
      end

      CONTENT_TYPE = 'Content-Type'.freeze
      APPLICATION_BINARY = 'application/binary'.freeze

    end
    # !SLIDE END
  end # class
end # module

