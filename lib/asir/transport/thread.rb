require 'asir/transport/local'
require 'thread'

module ASIR
  class Transport
    # !SLIDE
    # Thread Transport
    #
    # Send one-way Message to a Thread.
    class Thread < Local
      # Any object that responds to .new(&blk).
      # Defaults to ::Thread.
      attr_accessor :thread_class

      # Callback: call(self, message, thr).
      attr_accessor :after_thread_new

      def initialize *args
        @thread_class = ::Thread
        @one_way = true; super
      end

      def _send_message message, message_payload
        thr = thread_class.new do
          send_result(super, nil, nil)
        end
        @after_thread_new.call(self, message, thr) if @after_thread_new
        thr
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
