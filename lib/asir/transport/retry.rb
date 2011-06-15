require 'asir/transport/delegation'

module ASIR
  class Transport
    # !SLIDE
    # Retry Transport
    class Retry < self
      include Delegation

      # The transport to delegate to.
      attr_accessor :transport
      # Maximum trys.
      attr_accessor :max_try
      # Amount of seconds to sleep between each try.
      attr_accessor :sleep_between_try
      # Amount of seconds to increment between sleep.
      attr_accessor :sleep_increment
      # Proc to call before retry.
      attr_accessor :before_retry

      def _send_request request, request_payload
        n_try = 0
        sleep_secs = sleep_between_try
        result = sent = exceptions = nil
        begin
          n_try += 1
          $stderr.puts "n_try = #{n_try.inspect}"
          result = transport.send_request(request)
          sent = true
        rescue ::Exception => exc
          $stderr.puts "exc = #{exc.inspect}"
         _log { [ :send_request, :transport_failed, exc ] }
          (exceptions ||= [ ]) << [ transport, exc ]
          (request[:transport_exceptions] ||= [ ]) << "#{exc.inspect}\n#{exc.backtrace * "\n"}"
          if ! max_try || max_try > n_try
            before_retry.call(self, request) if before_retry
            if sleep_secs
              sleep sleep_secs
              sleep_secs += sleep_increment if sleep_increment
            end
            retry
          end
        end
        unless sent
          _log { [ :send_request, :retry_failed, exceptions ] }
          if exceptions && @reraise_first_exception
            $! = exceptions.first[1]
            raise
          end
          raise RetryError, "retry failed"
        end
        result
      end
      class RetryError < Error; end
    end
    # !SLIDE END
  end
end

