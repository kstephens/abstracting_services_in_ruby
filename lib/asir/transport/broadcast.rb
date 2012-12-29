require 'asir/transport/composite'

module ASIR
  class Transport
    # !SLIDE
    # Broadcast Transport
    #
    # Broadcast to multiple Transports.
    class Broadcast < self
      include Composite

      def _send_message state
        result = first_exception = nil
        transports.each do | transport |
          begin
            result = transport.send_message(state.message)
          rescue ::Exception => exc
            first_exception ||= exc
            _handle_send_message_exception! transport, state, exc
            raise exc unless @continue_on_exception
          end
        end
        if first_exception && @reraise_first_exception
          raise first_exception
        end
        state.result = Result.new(state.message, result)
      end
    end
    # !SLIDE END
  end
end

