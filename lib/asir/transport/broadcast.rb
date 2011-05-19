module ASIR
  class Transport
    # !SLIDE
    # Broadcast Transport
    #
    # Broadcast to multiple Transports.
    class Broadcast < self
      attr_accessor :transports

      def _send_request request, request_payload
        result = nil
        transports.each do | transport |
          _log { [ :send_request, :transport, transport ] }
          result = transport.send_request(request)
        end
        result
      end

      def _receive_response opaque
        opaque
      end

      def needs_request_identifier?
        transports.any? { | t | t.needs_request_identifier? }
      end
    end
    # !SLIDE END
  end
end

