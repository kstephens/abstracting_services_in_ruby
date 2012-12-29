module ASIR
  class Transport
    # !SLIDE 
    # Null Transport
    #
    # Never send Message.
    class Null < self
      def _send_message message_result
        nil
      end
    end
    # !SLIDE END
  end
end
