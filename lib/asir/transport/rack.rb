require 'asir/transport/http'
require 'rack'

module ASIR
  class Transport
    # !SLIDE
    # Rack Transport
    class Rack < HTTP
      # Receive the Message payload String from the Rack::Request object.
      def _receive_message message_result
        rack_request = message_result.in_stream
        message_result.message_payload = rack_request.body.read
      end

      # Send the Result payload String in the Rack::Response object as application/binary.
      def _send_result message_result
        rack_response = message_result.out_stream
        rack_response[CONTENT_TYPE] = APPLICATION_BINARY
        rack_response.write message_result.result_payload
      end

      # Constructs a Rackable App from this Transport.
      def rack_app &blk
        App.new(self, &blk)
      end

      # Rack Transport Application.
      class App
        def initialize transport = nil, &blk
          @app = transport
          instance_eval &blk if blk
        end

        def call env
          @app.call(env)
        end
      end

      # Rack application handler.
      def call(env)
        rq = ::Rack::Request.new(env)
        rs = ::Rack::Response.new
        serve_message! rq, rs
        rs.finish # => [ status, header, rbody ]
      end

      ###############################
      # Dummy server.

      def prepare_server! opts = { }
        self
      end

      # WEBrick under Rack.
      def run_server!
        #require 'rack/handler'
        u = URI.parse(uri); port = u.port # <= REFACTOR
        ::Rack::Handler::WEBrick.run \
          ::Rack::ShowExceptions.new(::Rack::Lint.new(self.rack_app)),
          :Port => port
        self
      end

      def stop_server!
        # NOT IMPLEMENTED
        self
      end
    end
    # !SLIDE END
  end
end
