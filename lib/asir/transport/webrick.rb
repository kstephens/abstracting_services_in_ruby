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
        [ http_message.body, http_message ]
      end

      # Send the Result payload String in the HTTP Response object as application/binary.
      def _send_result message, result, result_payload, http_result, message_state
        http_result[CONTENT_TYPE] = APPLICATION_BINARY
        http_result.body = result_payload
      end

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
        @server.start
        self
      end

      def stop_server!
        @server.stop
        self
      end
    end
    # !SLIDE END
  end
end
