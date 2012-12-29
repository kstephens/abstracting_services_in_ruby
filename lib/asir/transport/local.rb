module ASIR
  class Transport
    # !SLIDE
    # Local Transport
    #
    # Send Message to same process.
    # Requires Identity Coder.
    class Local < self
      # Capture Result object after invoking Message.
      def _send_message message_result
        invoke_message!(message_result)
        self
      end

      # Result object was captured in #_send_message.
      def _receive_result message_result
        message_result.result_payload = message_result.result
        self
      end
    end
    # !SLIDE END
  end
end
