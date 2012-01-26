require 'asir/transport/local'

module ASIR
  class Transport
    # !SLIDE
    # Subprocess Transport
    #
    # Send one-way Request to a forked subprocess.
    class Subprocess < Local
      def initialize *args
        @one_way = true; super
      end

      def _send_request request, request_payload
        Process.fork do
          send_response(super, nil, nil)
        end
      end

      # one-way; no Response
      def _receive_response request, opaque_response
      end

      # one-way; no Response
      def _send_response request, response, response_payload, stream, request_state
      end
    end
    # !SLIDE END
  end
end
