require 'time'
require 'asir/thread_variable'
require 'asir/message/delay'
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
      @message_count ||= 0; @message_count += 1
      message.create_timestamp! if needs_message_timestamp? message
      message.create_identifier! if needs_message_identifier? message
      @before_send_message.call(self, message) if @before_send_message
      relative_message_delay! message
      message_payload = encoder.dup.encode(message)
      opaque_result = _send_message(message, message_payload)
      receive_result(message, opaque_result)
    end

    # !SLIDE
    # Transport#receive_message
    # Receive Message payload from stream.
    def receive_message stream
      @message_count ||= 0; @message_count += 1
      additional_data = { }
      if req_and_state = _receive_message(stream, additional_data)
        message = req_and_state[0] = encoder.dup.decode(req_and_state.first)
        message.additional_data!.update(additional_data) if message
        if @after_receive_message
          begin
            @after_receive_message.call(self, message)
          rescue ::Exception => exc
            _log { [ :receive_message, :after_receive_message, :exception, exc ] }
          end
        end
      end
      req_and_state
    end
    # !SLIDE END

    # !SLIDE
    # Transport#send_result
    # Send Result to stream.
    def send_result result, stream, message_state
      message = result.message
      if @one_way && message.block
        message.block.call(result)
      else
        result.message = nil # avoid sending back entire Message.
        result_payload = decoder.dup.encode(result)
        _send_result(message, result, result_payload, stream, message_state)
      end
    end
    # !SLIDE END

    # !SLIDE
    # Transport#receive_result
    # Receieve Result from stream:
    # * Receive Result payload
    # * Decode Result.
    # * Extract Result result or exception.
    def receive_result message, opaque_result
      result_payload = _receive_result(message, opaque_result)
      result = decoder.dup.decode(result_payload)
      if result && ! message.one_way
        if exc = result.exception
          invoker.invoke!(exc, self)
        else
          if ! @one_way && message.block
            message.block.call(result)
          end
          result.result
        end
      end
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

    # Proc to call with exception, if exception occurs within #serve_message!, but outside
    # Message#invoke!.
    #
    # trans.on_exception.call(trans, exception, :message, Message_instance, nil)
    # trans.on_exception.call(trans, exception, :result, Message_instance, Result_instance)
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
      message = message_state = message_ok = result = result_ok = nil
      exception = original_exception = unforwardable_exception = nil
      message, message_state = receive_message(in_stream)
      if message
        message_ok = true
        result = invoke_message!(message)
        result_ok = true
        self
      else
        nil
      end
    rescue ::Exception => exc
      exception = original_exception = exc
      _log [ :message_error, exc ]
      @on_exception.call(self, exc, :message, message, nil) if @on_exception
    ensure
      begin
        if message_ok
          if exception && ! result_ok
            case exception
            when *Error::Unforwardable.unforwardable
              unforwardable_exception = exception = Error::Unforwardable.new(exception)
            end
            result = Result.new(message, nil, exception)
          end
          if out_stream
            send_result(result, out_stream, message_state)
          end
        end
      rescue ::Exception => exc
        _log [ :result_error, exc ]
        @on_exception.call(self, exc, :result, message, result) if @on_exception
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
      raise Error::Terminate if force
      self
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
    def invoke_message! message
      result = nil
      Transport.with_attr! :current, self do
        with_attr! :message, message do
          wait_for_delay! message
          result = invoker.invoke!(message, self)
          # Hook for Exceptions.
          if @on_result_exception && result.exception
            @on_result_exception.call(self, result)
          end
        end
      end
      result
    end
    # The current Message being handled.
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
