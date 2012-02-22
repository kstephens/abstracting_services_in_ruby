require 'time'

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
    include Log, Initialization, AdditionalData

    attr_accessor :encoder, :decoder, :one_way

    # Incremented for each message sent or received.
    attr_accessor :message_count

    # A Proc to call within #receive_message, after #_receive_message.
    # trans.after_receiver_message(trans, message)
    attr_accessor :after_receive_message

    # A Proc to call within #send_message, before #_send_message.
    # trans.before_send_message(trans, message)
    attr_accessor :before_send_message

    # Proc to call after #_send_result if result.exception.
    # trans.on_result_exception.call(trans, result)
    attr_accessor :on_result_exception

    # Proc to call with exception, if exception occurs within #serve_message!, but outside
    # Message#invoke!.
    #
    # trans.on_exception.call(trans, exception, :message, Message_instance)
    # trans.on_exception.call(trans, exception, :result, Result_instance)
    attr_accessor :on_exception

    attr_accessor :needs_message_identifier, :needs_message_timestamp
    alias :needs_message_identifier? :needs_message_identifier
    alias :needs_message_timestamp? :needs_message_timestamp

    attr_accessor :verbose

    def initialize *args
      @verbose = 0
      super
    end

    # !SLIDE
    # Transport#send_message 
    # * Encode Message.
    # * Send encoded Message.
    # * Receive decoded Result.
    def send_message message
      @message_count ||= 0; @message_count += 1
      message.create_timestamp! if needs_message_timestamp?
      message.create_identifier! if needs_message_identifier?
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
        # $stderr.puts "req_and_state = #{req_and_state.inspect}"
        message = req_and_state[0] = encoder.dup.decode(req_and_state.first)
        # $stderr.puts "req_and_state AFTER DECODE = #{req_and_state.inspect}"
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
      if @on_result_exception && result.exception
        begin
          @on_result_exception.call(self, result)
        rescue ::Exception => exc
          _log { [ :send_result, :result, result, :on_result_exception, exc ] }
        end
      end
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
      if result
        if exc = result.exception
          exc.invoke!
        else
          if ! @one_way && message.block
            message.block.call(result)
          end
          result.result
        end
      end
    end
    # !SLIDE END

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
      @on_exception.call(self, exc, :message, message) if @on_exception
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
        @on_exception.call(self, exc, :result, result) if @on_exception
      end
      raise original_exception if unforwardable_exception
    end

    # !SLIDE pause

    # !SLIDE 
    # Transport Server Support

    def with_server_signals!
      old_trap = { }
      [ "TERM", "HUP" ].each do | sig |
        trap = proc do | *args |
          @running = false
          unless @processing_message
            raise ::ASIR::Error::Terminate, "#{self} by SIG#{sig} #{args.inspect} in #{__FILE__}:#{__LINE__}"
          end
        end
        old_trap[sig] = Signal.trap(sig, trap)
      end
      yield
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
      _processing_message = @processing_message
      @processing_message = true
      wait_for_delay! message
      message.invoke!
    ensure
      @processing_message = _processing_message
    end

    # Returns the number of seconds from now, that the message should be delayed.
    # If message.delay is Numeric, sets message.delay to the Time to delay til.
    # If message.delay is Time, returns (now - message.delay).to_f
    # Returns Float if message.delay was set, or nil.
    # Returns 0 if delay has already expired.
    def relative_message_delay! message, now = nil
      case delay = message.delay
      when nil
      when Numeric
        now ||= Time.now
        delay = delay.to_f
        message.delay = (now + delay).utc
      when Time
        now ||= Time.now
        delay = (delay - now).to_f
        delay = 0 if delay < 0
      else
        raise TypeError, "Expected message.delay to be Numeric or Time, given #{delay.class}"
      end
      delay
    end

    def wait_for_delay! message
      while (delay = relative_message_delay!(message)) && delay > 0 
        sleep delay
      end
      self
    end

    # !SLIDE END
    # !SLIDE resume

    def stop! force = false
      @running = false
      raise Error::Terminate if force
      self
    end

  end
  # !SLIDE END
end
