require 'time'
require 'asir/thread_variable'
require 'asir/message/delay'
require 'asir/message/state'
require 'asir/transport/conduit'

module ASIR
  # !SLIDE
  # Transport
  #
  # Client: Send the Message to the Service.
  # Service: Receive the Message from the Client.
  # Service: Invoke the Message.
  # Service: Send the Result to the Client.
  # Client: Receive the Result from the Service.
  class Transport
    include Log, Initialization, AdditionalData, Message::Delay, ThreadVariable, Conduit

    attr_accessor :encoder, :decoder, :one_way

    # !SLIDE
    # Transport#send_message
    # * Encode Message.
    # * Send encoded Message.
    # * Receive decoded Result.
    def send_message message
      @message_count ||= 0; @message_count += 1 # NOT THREAD-SAFE
      message.create_timestamp! if needs_message_timestamp? message
      message.create_identifier! if needs_message_identifier? message
      relative_message_delay! message
      state = Message::State.new(:message => message, :message_payload => encoder.prepare.encode(message))
      @before_send_message.call(self, state) if @before_send_message
      _send_message(state)
      receive_result(state)
    end

    # !SLIDE
    # Transport#receive_message
    # Receive Message payload from stream.
    def receive_message state
      @message_count ||= 0; @message_count += 1 # NOT THREAD-SAFE
      if received = _receive_message(state)
        if message = state.message = encoder.prepare.decode(state.message_payload)
          message.additional_data!.update(state.additional_data) if state.additional_data
          @after_receive_message.call(self, state) if @after_receive_message
          self
        end
      end
    end
    # !SLIDE END

    # !SLIDE
    # Transport#send_result
    # Send Result to stream.
    def send_result state
      result = state.result
      message = state.message
      if @one_way && message.block
        message.block.call(result)
      else
        # Avoid sending back entire Message in Result.
        result.message = nil unless @coder_needs_result_message
        state.result_payload = decoder.prepare.encode(result)
        _send_result(state)
      end
    end
    attr_accessor :coder_needs_result_message

    # !SLIDE END

    # !SLIDE
    # Transport#receive_result
    # Receieve Result from stream:
    # * Receive Result payload
    # * Decode Result.
    # * Extract Result result or exception.
    # * Invoke Exception or return Result value.
    def receive_result state
      value = nil
      return value unless _receive_result(state)
      result = state.result ||= decoder.prepare.decode(state.result_payload)
      message = state.message
      if result && ! message.one_way
        result.message = message
        if exc = result.exception
          invoker.invoke!(exc, self)
        else
          if ! @one_way && message.block
            message.block.call(result)
          end
          value = result.result
        end
      end
      value
    end
    # !SLIDE END

    def initialize *args
      @verbose = 0
      super
    end

    # Incremented for each message sent or received.
    attr_accessor :message_count

    # A Proc to call within #receive_message, after #_receive_message.
    # trans.after_receive_message(trans, message)
    attr_accessor :after_receive_message

    # A Proc to call within #send_message, before #_send_message.
    # trans.before_send_message(trans, message)
    attr_accessor :before_send_message

    # Proc to call with #invoke_message! if result.exception.
    # trans.on_result_exception.call(trans, result)
    attr_accessor :on_result_exception

    # Proc to call after #invoke_message!
    # trans.after_invoke_message.call(trans, message, result)
    attr_accessor :after_invoke_message

    # Proc to call with exception, if exception occurs within #serve_message!, but outside
    # Message#invoke!.
    #
    # trans.on_exception.call(trans, exception, :message, message_state)
    # trans.on_exception.call(trans, exception, :result, message_state)
    attr_accessor :on_exception

    attr_accessor :needs_message_identifier, :needs_message_timestamp
    def needs_message_identifier? m; @needs_message_identifier; end
    def needs_message_timestamp?  m; @needs_message_timestamp; end

    attr_accessor :verbose

    def _subclass_responsibility *args
      raise Error::SubclassResponsibility "subclass responsibility"
    end
    alias :_send_message :_subclass_responsibility
    alias :_receive_message :_subclass_responsibility
    alias :_send_result :_subclass_responsibility
    alias :_receive_result :_subclass_responsibility

    # !SLIDE
    # Serve a Message.
    def serve_message! in_stream, out_stream
      state = message_ok = result = result_ok = nil
      exception = original_exception = unforwardable_exception = nil
      state = Message::State.new(:in_stream => in_stream, :out_stream => out_stream)
      if receive_message(state)
        message_ok = true
        invoke_message!(state)
        result_ok = true
        if @after_invoke_message
          @after_invoke_message.call(self, state)
        end
        self
      else
        nil
      end
    rescue *Error::Unrecoverable.modules
      raise
    rescue ::Exception => exc
      exception = original_exception = exc
      _log [ :message_error, exc ]
      @on_exception.call(self, exc, :message, state) if @on_exception
    ensure
      begin
        if message_ok
          if exception && ! result_ok
            case exception
            when *Error::Unforwardable.unforwardable
              unforwardable_exception = exception = Error::Unforwardable.new(exception)
            end
            state.result = Result.new(state.message, nil, exception)
          end
          if out_stream
            send_result(state)
          end
        end
      rescue *Error::Unrecoverable.modules
        raise
      rescue ::Exception => exc
        _log [ :result_error, exc, exc.backtrace ]
        @on_exception.call(self, exc, :result, state) if @on_exception
      end
      raise original_exception if unforwardable_exception
    end

    # !SLIDE pause

    # !SLIDE 
    # Transport Server Support
    attr_accessor :running

    def stop! force = false
      @running = false
      stop_server! if respond_to?(:stop_server!)
      raise Error::Terminate if force || @force_stop
      self
    end

    def with_force_stop!
      force_stop_save = @force_stop
      @force_stop = true
      yield
    ensure
      @force_stop = force_stop_save
    end

    def with_server_signals!
      old_trap = { }
      [ "TERM", "HUP" ].each do | sig |
        trap = proc do | *args |
          stop!
          @signal_exception = ::ASIR::Error::Terminate.new("#{self} by SIG#{sig} #{args.inspect} in #{__FILE__}:#{__LINE__}")
        end
        old_trap[sig] = Signal.trap(sig, trap)
      end
      yield
      if exc = @signal_exception
        @signal_exception = nil
        raise exc
      end
    ensure
      # $stderr.puts "old_trap = #{old_trap.inspect}"
      old_trap.each do | sig, trap |
        Signal.trap(sig, trap) rescue nil
      end
    end

    # !SLIDE
    # Transport Support
    # ...

    def encoder
      @encoder ||=
        Coder::Identity.new
    end

    def decoder
      @decoder ||=
        encoder
    end

    # Invokes the Message object, returns a Result object.
    def invoke_message! state
      Transport.with_attr! :current, self do
        with_attr! :message_state, state do
        with_attr! :message, state.message do
          wait_for_delay! state.message
          state.result = invoker.invoke!(state.message, self)
          # Hook for Exceptions.
          if @on_result_exception && state.result.exception
            @on_result_exception.call(self, state)
          end
        end
      end
      end
      self
    end

    # The current Message::State.
    attr_accessor_thread :message_state
    # The current Message being invoked.  DEPRECATED.
    attr_accessor_thread :message

    # The current active Transport.
    cattr_accessor_thread :current

    # The Invoker responsible for invoking the Message.
    attr_accessor :invoker
    def invoker
      @invoker ||= Invoker.new
    end

    # !SLIDE END
    # !SLIDE resume

  end
  # !SLIDE END
end
