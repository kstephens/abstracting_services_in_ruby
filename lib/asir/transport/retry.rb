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
      # Proc to call(transport, message) before retry.
      attr_accessor :before_retry

      def _send_message message_result
        first_exception = nil
        with_retry do | action, data |
          case action
          when :try
            result = transport.send_message(message_result.message)
            message_result.result = Result.new(message_result.message, result)
          when :rescue #, exc
            first_exception ||= data
            _handle_send_message_exception! transport, message_result, data
          when :retry #, exc
            before_retry.call(self, message_result) if before_retry
          when :failed
            @on_failed_message.call(self, message_result) if @on_failed_message
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

