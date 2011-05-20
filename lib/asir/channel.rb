require 'asir'

module ASIR
  # Generic I/O Channel abstraction.
  # Handles stream per Thread and forked child processes.
  class Channel
    include Initialization

    attr_accessor :on_connect, :on_close, :on_error
    
    ON_ERROR = lambda do | channel, exc, action, stream |
      channel.close rescue nil if stream
      raise exc
    end
    ON_CLOSE = lambda do | channel, stream |
      stream.close
    end

    def initialize opts = nil
      @on_close = ON_CLOSE
      @on_error = ON_ERROR
      super
    end

    # Returns IO stream for current Thread.
    # Automatically calls #connect! if stream is created.
    def stream
      _streams[self] ||= 
        connect!
    end
    
    # Invokes @on_connect.call(self).
    # On Exception, invokes @on_error.call(self, :connect, exc).
    def connect!
      @on_connect.call(self)
    rescue Exception => exc
      handle_error!(exc, :connect, nil)
    end
    
    # Invokes @on_close.call(self, stream).
    # On Exception, invokes @on_error.call(self, :close, exc, stream).
    def close
      if stream = _stream
        self.stream = nil
        @on_close.call(self, stream)
      end
    rescue Exception => exc
      handle_error!(exc, :close, stream)
    end
    
    # Yield #stream to block.
    # On Exception, invokes @on_error.call(self, exc, :with_stream, stream).
    def with_stream!
      x = stream
      begin
        yield x
      rescue Exception => exc
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
      streams = Thread.current[:'ASIR::Channel._streams'] ||= { }
      if ! @owning_process || 
          @owning_process != $$ || # child process?
          @owning_process > $$ # PIDs wrapped around?
        @owning_process = $$
        streams.clear
      end
      streams
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


