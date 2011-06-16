require 'asir/transport/composite'

module ASIR
  class Transport
    # !SLIDE
    # Fallback Transport
    class Fallback < self
      include Composite

      def _send_request request, request_payload
        result = sent = first_exception = nil
        transports.each do | transport |
          begin
            result = transport.send_request(request)
            sent = true
            break
          rescue ::Exception => exc
            first_exception ||= exc
            _handle_send_request_exception! transport, request, exc
          end
        end
        unless sent
          _log { [ :send_request, :fallback_failed, first_exception ] }
          if first_exception && @reraise_first_exception
            $! = first_exception
            raise
          end
          raise FallbackError, "fallback failed"
        end
        result
      end
      class FallbackError < Error; end
    end
    # !SLIDE END
  end
end

