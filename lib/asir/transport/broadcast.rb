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
        result = first_exception = nil
        transports.each do | transport |
          begin
            result = transport.send_request(request)
          rescue ::Exception => exc
            first_exception ||= exc
            _handle_send_request_exception! transport, request, exc
            raise unless @continue_on_exception
          end
        end
        if first_exception && @reraise_first_exception
          $! = first_exception
          raise
        end
        result
      end

    end
    # !SLIDE END
  end
end

