require 'asir/transport/composite'

module ASIR
  class Transport
    # !SLIDE
    # Broadcast Transport
    #
    # Broadcast to multiple Transports.
    class Broadcast < self
      include Composite

      def _send_request request, request_payload
        result = exceptions = nil
        transports.each do | transport |
          begin
            _log { [ :send_request, :transport, transport ] }
            result = transport.send_request(request)
          rescue ::Exception => exc
            _log { [ :send_request, :transport_failed, exc ] }
            (exceptions ||= [ ]) << [ transport, exc ]
            raise unless @continue_on_exception
          end
        end
        if exceptions && @reraise_first_exception
          $! = exceptions.first[1]
          raise
        end
        result
      end

      def _receive_response opaque
        opaque
      end

    end
    # !SLIDE END
  end
end

