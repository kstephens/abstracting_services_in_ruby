require 'asir/transport/local'

module ASIR
  class Transport
    # !SLIDE
    # Subprocess Transport
    #
    # Send one-way Request to a forked subprocess.
    class Subprocess < Local
      def _send_request request, request_payload
        Process.fork do 
          super
        end
        nil # opaque_response
      end

      # one-way; no Response
      def _receive_response request, opaque_response
        nil
      end
    end
    # !SLIDE END
  end
end
