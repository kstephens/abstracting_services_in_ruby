module ASIR
  class Transport
    # !SLIDE
    # Local Transport
    #
    # Send Request to same process.
    # Requires a Identity Coder.
    class Local < self
      # Returns Response object.
      def _send_request request, request_payload
        invoke_request!(request)
      end

      # Returns Response object from #_send_request.
      def _receive_response request, opaque_response
        opaque_response
      end
    end
    # !SLIDE END
  end
end
