require 'asir/transport'
require 'asir/transport/delegation'
require 'thread'

module ASIR
  class Transport
    # !SLIDE
    # Buffer Transport
    #
    # Buffers Messages until #flush!
    # Assumes One-way Messages.
    class Buffer < self
      include Delegation

      # Transport to send_message.
      attr_accessor :transport

      def initialize *args
        super
        @messages = Queue.new
        @messages_mutex = Mutex.new
        @paused = 0
        @paused_mutex = Mutex.new
      end

      # If paused, queue messages,
      # Otherwise delegate immediately to #transport.
      def _send_message state
        return nil if @ignore
        if paused?
          @messages_mutex.synchronize do
            @messages << state.message
          end
          nil
        else
          @transport.send_message(state.message)
        end
      end

      # Returns true if currently paused.
      # Messages are queued until #resume!.
      def paused?
        @paused > 0
      end

      # Pauses all messages until resume!.
      # May be called multiple times.
      def pause!
        @paused_mutex.synchronize do
          @paused += 1
        end
        self
      end

      # Will automatically call #flush! when not #paused?.
      def resume!
        should_flush = @paused_mutex.synchronize do
          @paused -= 1 if @paused > 0
          @paused == 0
        end
        flush! if should_flush
        self
      end

      def size
        @messages_mutex.synchronize do
          @messages.size
        end
      end

      # Will flush pending Messages even if ! #paused?.
      def flush!
        clear!.each do | message |
          @transport.send_message(message)
        end
        self
      end

      # Clear all pending Messages without sending them.
      # Returns Array of Messages that would have been sent.
      def clear!
        messages = [ ]
        @messages_mutex.synchronize do
          @messages.size.times do
            messages << @messages.shift(true)
          end
        end
        messages
      end

      # Take Message from head of Queue.
      def shift non_block=false
        @messages.shift(non_block)
      end

      # Processes queue.
      # Usually used in worker Thread.
      def process! non_block=false
        @running = true
        while @running && (message = shift(non_block))
          @transport.send_message(message)
        end
        message
      end

      # Stop processing queue.
      def stop!
        @messages_mutex.synchronize do
          @ignore = true; @running = false
        end
        self
      end
    end
    # !SLIDE END
  end
end
