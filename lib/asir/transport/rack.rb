require 'asir/transport/http'
require 'rack'

module ASIR
  class Transport
    # !SLIDE
    # Rack Transport
    class Rack < HTTP
      # Receive the Message payload String from the Rack::Request object.
      # Returns the [ Rack::Request, Rack::Response ] as the message_state.
      def _receive_message rack_req_res, additional_data
        body = rack_req_res.first.body.read
        [ body, rack_req_res ]
      end

      # Send the Result payload String in the Rack::Response object as application/binary.
      def _send_result message, result, result_payload, rack_rq_rs, message_state
        rack_response = rack_rq_rs[1]
        rack_response[CONTENT_TYPE] = APPLICATION_BINARY
        rack_response.write result_payload
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
        rack_rq_rs = [ rq, rs ]
        serve_message! rack_rq_rs, rack_rq_rs
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
