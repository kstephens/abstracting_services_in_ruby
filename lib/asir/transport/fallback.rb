require 'asir/transport/composite'

module ASIR
  class Transport
    # !SLIDE
    # Fallback Transport
    class Fallback < self
      include Composite

      def _send_message message_result
        result = sent = first_exception = nil
        transports.each do | transport |
          begin
            result = transport.send_message(message_result.message)
            sent = true
            break
          rescue ::Exception => exc
            first_exception ||= exc
            _handle_send_message_exception! transport, message_result, exc
          end
        end
        unless sent
          if first_exception && @reraise_first_exception
            raise first_exception
          end
          raise FallbackError, "fallback failed"
        end
        message_result.result = Result.new(message_result.message, result)
      end
      class FallbackError < Error; end
    end
    # !SLIDE END
  end
end

