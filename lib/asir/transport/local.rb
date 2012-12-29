module ASIR
  class Transport
    # !SLIDE
    # Local Transport
    #
    # Send Message to same process.
    # Requires Identity Coder.
    class Local < self
      # Capture Result object after invoking Message.
      def _send_message state
        invoke_message!(state)
        self
      end

      # Result object was captured in #_send_message.
      def _receive_result state
        state.result_payload = state.result
        self
      end
    end
    # !SLIDE END
  end
end
