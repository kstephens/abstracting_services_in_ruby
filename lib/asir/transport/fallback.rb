require 'asir/transport/composite'

module ASIR
  class Transport
    # !SLIDE
    # Fallback Transport
    class Fallback < self
      include Composite

      def _send_message state
        result = sent = first_exception = nil
        transports.each do | transport |
          begin
            result = transport.send_message(state.message)
            sent = true
            break
          rescue *Error::Unrecoverable.modules
            raise
          rescue ::Exception => exc
            first_exception ||= exc
            _handle_send_message_exception! transport, state, exc
          end
        end
        unless sent
          if first_exception && @reraise_first_exception
            raise first_exception
          end
          raise FallbackError, "fallback failed"
        end
        state.result = Result.new(state.message, result)
      end
      class FallbackError < Error; end
    end
    # !SLIDE END
  end
end

