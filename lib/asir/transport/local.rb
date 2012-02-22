module ASIR
  class Transport
    # !SLIDE
    # Local Transport
    #
    # Send Message to same process.
    # Requires a Identity Coder.
    class Local < self
      # Returns Result object after invoking Message.
      def _send_message message, message_payload
        invoke_message!(message)
      end

      # Returns Result object from #send_message.
      def _receive_result message, opaque_result
        opaque_result
      end
    end
    # !SLIDE END
  end
end
