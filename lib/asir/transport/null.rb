module ASIR
  class Transport
    # !SLIDE 
    # Null Transport
    #
    # Never send Message.
    class Null < self
      def _send_message message, message_payload
        nil
      end
    end
    # !SLIDE END
  end
end
