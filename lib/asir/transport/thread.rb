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

      # Callback: call(self, message_result, thr).
      attr_accessor :after_thread_new

      def initialize *args
        @thread_class = ::Thread
        @one_way = true; super
      end

      def _send_message message_result
        thr = thread_class.new do
          super
          send_result(message_result)
        end
        message_result.in_stream = thr
        @after_thread_new.call(self, message_result, thr) if @after_thread_new
        thr
      end

      # one-way; no Result
      def _receive_result message_result
      end

      # one-way; no Result
      def _send_result message_result
      end

      # one-may; no Result
      def receive_result message_result
      end
    end
    # !SLIDE END
  end
end
