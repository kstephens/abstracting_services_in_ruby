require 'time'

module ASIR
  # !SLIDE
  # Transport
  #
  # Client: Send the Request to the Service.
  # Service: Receive the Request from the Client.
  # Service: Invoke the Request.
  # Service: Send the Response to the Client.
  # Client: Receive the Response from the Service.
  class Transport
    include Log, Initialization, AdditionalData

    attr_accessor :encoder, :decoder

    # Incremented for each request sent or received.
    attr_accessor :request_count

    # A Proc to call within #receive_request, after #_receive_request.
    # trans.after_receiver_request(trans, request)
    attr_accessor :after_receive_request

    # A Proc to call within #send_request, before #_send_request.
    # trans.before_send_request(trans, request)
    attr_accessor :before_send_request

    # Proc to call after #_send_response if response.exception.
    # trans.on_response_exception.call(trans, response)
    attr_accessor :on_response_exception

    # Proc to call with exception, if exception occurs within #serve_request!, but outside
    # Request#invoke!.
    #
    # trans.on_exception.call(trans, exception, :request, Request_instance)
    # trans.on_exception.call(trans, exception, :response, Response_instance)
    attr_accessor :on_exception

    attr_accessor :needs_request_identifier, :needs_request_timestamp
    alias :needs_request_identifier? :needs_request_identifier
    alias :needs_request_timestamp? :needs_request_timestamp

    attr_accessor :verbose

    def initialize *args
      @verbose = 0
      super
    end

    # !SLIDE
    # Transport#send_request 
    # * Encode Request.
    # * Send encoded Request.
    # * Receive decoded Response.
    def send_request request
      @request_count ||= 0; @request_count += 1
      request.create_timestamp! if needs_request_timestamp?
      request.create_identifier! if needs_request_identifier?
      @before_send_request.call(self, request) if @before_send_request
      relative_request_delay! request
      request_payload = encoder.dup.encode(request)
      opaque_response = _send_request(request, request_payload)
      receive_response opaque_response
    end

    # !SLIDE
    # Transport#receive_request
    # Receive Request payload from stream.
    def receive_request stream
      @request_count ||= 0; @request_count += 1
      additional_data = { }
      if req_and_state = _receive_request(stream, additional_data)
        # $stderr.puts "req_and_state = #{req_and_state.inspect}"
        request = req_and_state[0] = encoder.dup.decode(req_and_state.first)
        # $stderr.puts "req_and_state AFTER DECODE = #{req_and_state.inspect}"
        request.additional_data!.update(additional_data) if request
        if @after_receive_request
          begin
            @after_receive_request.call(self, request)
          rescue ::Exception => exc
            _log { [ :receive_request, :after_receive_request, :exception, exc ] }
          end
        end
      end
      req_and_state
    end
    # !SLIDE END

    # !SLIDE
    # Transport#send_response
    # Send Response to stream.
    def send_response response, stream, request_state
      request = response.request
      if @on_response_exception && response.exception
        begin
          @on_response_exception.call(self, response)
        rescue ::Exception => exc
          _log { [ :send_response, :response, response, :on_response_exception, exc ] }
        end
      end
      response.request = nil # avoid sending back entire Request.
      response_payload = decoder.dup.encode(response)
      _send_response(request, response, response_payload, stream, request_state)
    end
    # !SLIDE END

    # !SLIDE
    # Transport#receive_response
    # Receieve Response from stream:
    # * Receive Response payload
    # * Decode Response.
    # * Extract Response result or exception.
    def receive_response opaque_response
      response_payload = _receive_response opaque_response
      response = decoder.dup.decode(response_payload)
      if response
        if exc = response.exception
          exc.invoke!
        else
          response.result
        end
      else
        response
      end
    end
    # !SLIDE END


    def _subclass_responsibility *args
      raise "subclass responsibility"
    end
    alias :_send_request :_subclass_responsibility
    alias :_receive_request :_subclass_responsibility
    alias :_send_response :_subclass_responsibility
    alias :_receive_response :_subclass_responsibility

    # !SLIDE
    # Serve a Request.
    def serve_request! in_stream, out_stream
      request = request_state = request_ok = response = response_ok = nil
      exception = original_exception = unforwardable_exception = nil
      request, request_state = receive_request(in_stream)
      if request
        request_ok = true
        response = invoke_request!(request)
        response_ok = true
        self
      else
        nil
      end
    rescue ::Exception => exc
      exception = original_exception = exc
      _log [ :request_error, exc ]
      @on_exception.call(self, exc, :request, request) if @on_exception
    ensure
      begin
        if request_ok
          if exception && ! response_ok
            case exception
            when *Error::Unforwardable.unforwardable
              unforwardable_exception = exception = Error::Unforwardable.new(exception)
            end
            response = Response.new(request, nil, exception)
          end
          if out_stream
            send_response(response, out_stream, request_state)
          end
        end
      rescue ::Exception => exc
        _log [ :response_error, exc ]
        @on_exception.call(self, exc, :response, response) if @on_exception
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
          unless @processing_request
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

    # Invokes the Request object, returns a Response object.
    def invoke_request! request
      _processing_request = @processing_request
      @processing_request = true
      wait_for_delay! request
      request.invoke!
    ensure
      @processing_request = _processing_request
    end

    # Returns the number of seconds from now, that the request should be delayed.
    # If request.delay is Numeric, sets request.delay to the Time to delay til.
    # If request.delay is Time, returns (now - request.delay).to_f
    # Returns Float if request.delay was set, or nil.
    # Returns 0 if delay has already expired.
    def relative_request_delay! request, now = nil
      case delay = request.delay
      when nil
      when Numeric
        now ||= Time.now
        delay = delay.to_f
        request.delay = (now + delay).utc
      when Time
        now ||= Time.now
        delay = (delay - now).to_f
        delay = 0 if delay < 0
      else
        raise TypeError, "Expected request.delay to be Numeric or Time, given #{delay.class}"
      end
      delay
    end

    def wait_for_delay! request
      while (delay = relative_request_delay!(request)) && delay > 0 
        sleep delay
      end
      self
    end

    # !SLIDE END
    # !SLIDE resume

  end
  # !SLIDE END
end
