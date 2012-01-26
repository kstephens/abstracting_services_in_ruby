module ASIR
  class Transport
    # !SLIDE
    # Local Transport
    #
    # Send Request to same process.
    # Requires a Identity Coder.
    class Local < self
      # Returns Response object after invoking Request.
      def _send_request request, request_payload
        invoke_request!(request)
      end

      # Returns Response object from #send_request.
      def _receive_response request, opaque_response
        opaque_response
      end
    end
    # !SLIDE END
  end
end
