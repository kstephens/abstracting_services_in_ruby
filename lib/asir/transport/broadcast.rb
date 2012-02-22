require 'asir/transport/composite'

module ASIR
  class Transport
    # !SLIDE
    # Broadcast Transport
    #
    # Broadcast to multiple Transports.
    class Broadcast < self
      include Composite

      def _send_message message, message_payload
        result = first_exception = nil
        transports.each do | transport |
          begin
            result = transport.send_message(message)
          rescue ::Exception => exc
            first_exception ||= exc
            _handle_send_message_exception! transport, message, exc
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

