require 'asir/transport/local'

module ASIR
  class Transport
    # !SLIDE
    # Subprocess Transport
    #
    # Send one-way Message to a forked subprocess.
    class Subprocess < Local
      def initialize *args
        @one_way = true; super
      end

      def _send_message message, message_payload
        Process.fork do
          send_result(super, nil, nil)
        end
      end

      # one-way; no Result
      def _receive_result message, opaque_result
      end

      # one-way; no Result
      def _send_result message, result, result_payload, stream, message_state
      end
    end
    # !SLIDE END
  end
end
