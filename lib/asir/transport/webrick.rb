require 'asir/transport/http'
require 'webrick'

module ASIR
  class Transport
    # !SLIDE
    # WEBrick Transport server.
    class Webrick < HTTP

      # Server-side: WEBrick

      # Receive the Message payload from the HTTP Message body.
      def _receive_message message_result
        http_message = message_result.in_stream
        message_result.message_payload = http_message.body
        message_result.message_opaque  = http_message
      end

      # Send the Result payload in the HTTP Response body as application/binary.
      def _send_result message_result
        http_result = message_result.out_stream
        http_result[CONTENT_TYPE] = APPLICATION_BINARY
        http_result.body = message_result.result_payload
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
