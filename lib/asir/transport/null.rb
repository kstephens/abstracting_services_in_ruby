module ASIR
  class Transport
    # !SLIDE 
    # Null Transport
    #
    # Never send Message.
    class Null < self
      def _send_message state
        nil
      end
    end
    # !SLIDE END
  end
end
