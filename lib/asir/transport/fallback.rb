module ASIR
  class Transport
    # !SLIDE
    # Fallback Transport
    class Fallback < self
      attr_accessor :transports

      def send_request request
        result = sent = exceptions = nil
        transports.each do | transport |
          begin
            _log { [ :send_request, :transport, transport ] }
            result = transport.send_request request
            sent = true
            break
          rescue ::Exception => exc
            (exceptions ||= [ ]) << [ transport, exc ]
            _log { [ :send_request, :transport_failed, transport, exc ] }
          end
        end
        unless sent
          _log { [ :send_request, :fallback_failed, exceptions ] }
          raise FallbackError, "fallback failed"
        end
        result
      end
      class FallbackError < Error; end
    end
    # !SLIDE END
  end
end

