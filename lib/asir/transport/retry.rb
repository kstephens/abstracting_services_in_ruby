require 'asir/transport/delegation'
require 'asir/retry_behavior'

module ASIR
  class Transport
    # !SLIDE
    # Retry Transport
    class Retry < self
      include Delegation, RetryBehavior

      # The transport to delegate to.
      attr_accessor :transport
      # Proc to call(transport, request) before retry.
      attr_accessor :before_retry

      def _send_request request, request_payload
        first_exception = nil
        with_retry do | action, data |
          case action
          when :try
            transport.send_request(request)
          when :rescue #, exc
            first_exception ||= data
            _handle_send_request_exception! transport, request, data
          when :retry #, exc
            before_retry.call(self, request) if before_retry
          when :failed
            _log { [ :send_request, :retry_failed, first_exception ] }
            @on_failed_request.call(self, request) if @on_failed_request
            if first_exception && @reraise_first_exception
              $! = first_exception
              raise
            end
            nil # fallback to raise RetryError
          end
        end
      end
    end
    # !SLIDE END
  end
end

