require 'asir/transport/composite'

module ASIR
  class Transport
    # !SLIDE
    # Fallback Transport
    class Fallback < self
      include Composite

      def _send_request request, request_payload
        result = sent = exceptions = nil
        transports.each do | transport |
          begin
            result = transport.send_request request
            sent = true
            break
          rescue ::Exception => exc
            _log { [ :send_request, :transport_failed, exc ] }
            (exceptions ||= [ ]) << [ transport, exc ]
            (request[:transport_exceptions] ||= [ ]) << "#{exc.inspect}\n#{exc.backtrace * "\n"}"
          end
        end
        unless sent
          _log { [ :send_request, :fallback_failed, exceptions ] }
          raise FallbackError, "fallback failed"
        end
        if exceptions && @reraise_first_exception
          $! = exceptions.first[1]
          raise
        end
        result
      end
      class FallbackError < Error; end
    end
    # !SLIDE END
  end
end

