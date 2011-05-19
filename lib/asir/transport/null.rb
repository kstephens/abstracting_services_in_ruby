module ASIR
  class Transport
    # !SLIDE 
    # Null Transport
    #
    # Never send Request.
    class Null < self
      def _send_request request, request_payload
        nil
      end
    end
    # !SLIDE END
  end
end
