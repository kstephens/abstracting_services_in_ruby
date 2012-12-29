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

      # Callback: call(self, MessageState, thr).
      attr_accessor :after_thread_new

      def initialize *args
        @thread_class = ::Thread
        @one_way = true; super
      end

      def _send_message state
        thr = thread_class.new do
          super
          send_result(state)
        end
        state.in_stream = thr
        @after_thread_new.call(self, state, thr) if @after_thread_new
        thr
      end

      # one-way; no Result
      def _receive_result state
      end

      # one-way; no Result
      def _send_result state
      end

      # one-may; no Result
      def receive_result state
      end
    end
    # !SLIDE END
  end
end
