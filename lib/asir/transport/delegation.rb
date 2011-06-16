module ASIR
  class Transport
    # !SLIDE
    # A Transport that delgated to one or more other Transports.
    #
    # Classes that include this must define #_send_request(request, request_payload).
    module Delegation
      # If true, reraise the first Exception that occurred during Transport#send_request.
      attr_accessor :reraise_first_exception

      # Proc to call(transport, request, exc) when a delegated #send_request fails.
      attr_accessor :on_send_request_exception

      # Proc to call(transport, request) when #send_request fails with no recourse.
      attr_accessor :on_failed_request

      # Return the subTransports#send_request result unmodified from #_send_request.
      def _receive_response opaque_response
        opaque_response
      end

      # Return the subTransports#send_request result unmodified from #_send_request.
      def receive_response opaque_response
        opaque_response
      end

      def needs_request_identifier?
        @needs_request_identifier || 
          transports.any? { | t | t.needs_request_identifier? }
      end

      def needs_request_timestamp?
        @needs_request_timestamp ||
          transports.any? { | t | t.needs_request_timestamp? }
      end

      # Subclasses with multiple transport should override this method. 
      def transports
        @transports ||= [ transport ]
      end

      # Called from within _send_request rescue.
      def _handle_send_request_exception! transport, request, exc
        _log { [ :send_request, :transport_failed, exc ] }
        (request[:transport_exceptions] ||= [ ]) << "#{exc.inspect}\n#{exc.backtrace * "\n"}"
        @on_send_request_exception.call(self, request, exc) if @on_send_request_exception
        self
      end
    end
    # !SLIDE END
  end
end

