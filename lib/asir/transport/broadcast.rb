require 'asir/transport/composite'

module ASIR
  class Transport
    # !SLIDE
    # Broadcast Transport
    #
    # Broadcast to multiple Transports.
    class Broadcast < self
      include Composite

      def _send_message message_result
        result = first_exception = nil
        transports.each do | transport |
          begin
            result = transport.send_message(message_result.message)
          rescue ::Exception => exc
            first_exception ||= exc
            _handle_send_message_exception! transport, message_result, exc
            raise exc unless @continue_on_exception
          end
        end
        if first_exception && @reraise_first_exception
          raise first_exception
        end
        message_result.result = Result.new(message_result.message, result)
      end
    end
    # !SLIDE END
  end
end

