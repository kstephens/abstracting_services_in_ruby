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

      def _send_message state
        Process.fork do
          super
          send_result(state)
        end
      end

      # one-way; no Result
      def _receive_result state
      end

      # one-way; no Result
      def _send_result state
      end
    end
    # !SLIDE END
  end
end
