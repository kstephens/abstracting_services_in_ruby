module ASIR
  class Transport
    # !SLIDE
    # A Transport composed of other Transports.
    #
    # Classes that mix this in should define #_send_request(request, request_payload).
    module Composite
      # Enumerable of Transport objects.
      attr_accessor :transports
      # If true, continue with other Transports when Transport#send_request throws an Exception.
      attr_accessor :continue_on_exception
      # If true, reraise the first Exception that occured during Transport#send_request.
      attr_accessor :reraise_first_exception

      # Return the subTransports#send_request result unmodified from #_send_request.
      def _receive_response opaque
        opaque
      end

      def needs_request_identifier?
        @needs_request_identifier || 
          transports.any? { | t | t.needs_request_identifier? }
      end

      def needs_request_timestamp?
        @needs_request_timestamp ||
          transports.any? { | t | t.needs_request_timestamp? }
      end
    end
    # !SLIDE END
  end
end

