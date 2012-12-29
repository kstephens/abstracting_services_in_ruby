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

      def _send_message message_result
        Process.fork do
          super
          send_result(message_result)
        end
      end

      # one-way; no Result
      def _receive_result message_result
      end

      # one-way; no Result
      def _send_result message_result
      end
    end
    # !SLIDE END
  end
end
