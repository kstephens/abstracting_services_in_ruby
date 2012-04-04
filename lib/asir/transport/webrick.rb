require 'asir/transport/http'
require 'webrick'

module ASIR
  class Transport
    # !SLIDE
    # WEBrick Transport server.
    class Webrick < HTTP

      # Server-side: WEBrick

      # Receive the Message payload String from the HTTP Message object.
      # Returns the original http_message as the message_state.
      def _receive_message http_message, additional_data
        $stderr.puts " ### http_message.body.encoding = #{http_message.body.encoding.inspect}" rescue nil
        [ http_message.body, http_message ]
      end

      # Send the Result payload String in the HTTP Response object as application/binary.
      def _send_result message, result, result_payload, http_result, message_state
        $stderr.puts " ### result_payload.encoding = #{result_payload.encoding.inspect}" rescue nil
        http_result[CONTENT_TYPE] = APPLICATION_BINARY
        http_result.body = result_payload
      end

      # TODO: rename prepare_webrick_server!
      def prepare_server! opts = { }
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

      def run_server!
        $stderr.puts " ### START webrick pid #{$$}"
        @server.start
        self
      end

      def stop_server!
        $stderr.puts " ### STOP webrick pid #{$$}"
        @server.stop
        self
      end
    end
    # !SLIDE END
  end
end
