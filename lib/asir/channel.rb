require 'asir'
require 'asir/retry_behavior'
require 'thread'

module ASIR
  # Generic I/O Channel abstraction.
  # Handles stream per Thread and forked child processes.
  class Channel
    include Initialization, RetryBehavior

    attr_accessor :on_connect, :on_close, :on_retry, :on_error
    
    ON_ERROR = lambda do | channel, exc, action, stream |
      channel.close rescue nil
      raise exc
    end
    ON_CLOSE = lambda do | channel, stream |
      stream.close rescue nil if stream
    end
    ON_RETRY = lambda do | channel, exc, action |
    end

    def initialize opts = nil
      @mutex = Mutex.new
      @on_close = ON_CLOSE
      @on_error = ON_ERROR
      # @on_retry = ON_RETRY
      self.try_max = 10
      self.try_sleep = 0.1
      self.try_sleep_increment = 0.1
      self.try_sleep_max = 10
      super
    end

    # Returns IO stream for current Thread.
    # Automatically calls #connect! if stream is created.
    def stream
      _streams[self] ||= 
        connect!
    end
    
    # Invokes @on_connect.call(self).
    # On Exception, invokes @on_error.call(self, exc, :connect, nil).
    def connect!
      n_try = nil
      with_retry do | action, data |
        case action
        when :try
          n_try = data
          @on_connect.call(self)
        when :retry #, exc
          exc = data
          case exc
          when *Error::Unrecoverable.modules
            raise exc
          end
          $stderr.puts "RETRY: #{n_try}: ERROR : #{data.inspect}"
          @on_retry.call(self, exc, :connect) if @on_retry
        when :failed
          exc = data
          $stderr.puts "FAILED: #{n_try}: ERROR : #{data.inspect}"
          handle_error!(exc, :connect, nil)
        end
      end
    end

    # Invokes @on_close.call(self, stream).
    # On Exception, invokes @on_error.call(self, exc, :close, stream).
    def close
      if stream = _stream
        self.stream = nil
        @on_close.call(self, stream) if @on_close
      end
    rescue *Error::Unrecoverable.modules
      raise
    rescue ::Exception => exc
      handle_error!(exc, :close, stream)
    end
    
    # Yield #stream to block.
    # On Exception, invokes @on_error.call(self, exc, :with_stream, stream).
    def with_stream!
      x = stream
      begin
        yield x
      rescue *Error::Unrecoverable.modules
        raise
      rescue ::Exception => exc
        handle_error!(exc, :with_stream, x)
      end
    end
    
    # Delegate to actual stream.
    def method_missing sel, *args, &blk
      with_stream! do | obj |
        obj.__send__(sel, *args, &blk)
      end
    end

    # Dispatches exception and arguments if @on_error is defined.
    # Otherwise, reraise exception.
    def handle_error! exc, action, stream
      if @on_error
        @on_error.call(self, exc, action, stream)
      else
        raise exc
      end
    end
    
    # Returns a Thread-specific mapping, unique to this process id. 
    # Maps from Channel objects to actual stream.
    def _streams
      @mutex.synchronize do
      streams = Thread.current[:'ASIR::Channel._streams'] ||= { }
      if  @owning_process != $$ || # child process?
          @owning_process > $$     # PIDs wrapped around?
        @owning_process = $$
        streams.clear
      end
      streams
      end
    end
    
    # Returns the stream for this Channel, or nil.
    def _stream
      _streams[self]
    end
    
    # Sets the stream for this Channel, or nil.
    def stream= x
      if x == nil
        _streams.delete(self)
      else
        _streams[self] = x
      end
    end
    
  end # class Channel
end # module


