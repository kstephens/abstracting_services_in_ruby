module ASIR
  class Message
    module Delay
      # Returns the number of seconds from now, that the message should be delayed.
      # If message.delay is Numeric, sets message.delay to the Time to delay til.
      # If message.delay is Time, returns (now - message.delay).to_f
      # Returns Float if message.delay was set, or nil.
      # Returns 0 if delay has already expired.
      def relative_message_delay! message, now = nil
        case delay = message.delay
        when nil
        when Numeric
          now ||= Time.now
          delay = delay.to_f
          message.delay = (now + delay).utc
        when Time
          now ||= Time.now
          delay = (delay - now).to_f
          delay = 0 if delay < 0
        else
          raise TypeError, "Expected message.delay to be Numeric or Time, given #{delay.class}"
        end
        delay
      end

      def wait_for_delay! message
        while (delay = relative_message_delay!(message)) && delay > 0 
          sleep delay
        end
        self
      end

    end
  end
end
