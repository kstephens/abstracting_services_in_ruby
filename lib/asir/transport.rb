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
    include Log, Initialization

    attr_accessor :encoder, :decoder

    # Incremented for each request sent or received.
    attr_accessor :request_count

    # A Proc to call on Request within
    attr_accessor :before_send_request

    # Proc to call(response) with Response after #_send_response if response.exception.
    attr_accessor :on_response_exception

    # Proc to call with exception, if exception occurs within #serve_request!, but outside
    # Request#invoke!.
    #
    # on_exception(exception, :request, Request_instance)
    # on_exception(exception, :response, Response_instance)
    attr_accessor :on_exception

    attr_accessor :needs_request_identifier, :needs_request_timestamp
    alias :needs_request_identifier? :needs_request_identifier
    alias :needs_request_timestamp? :needs_request_timestamp

    # !SLIDE
    # Transport#send_request 
    # * Encode Request.
    # * Send encoded Request.
    # * Receive decoded Response.
    def send_request request
      @request_count ||= 0; @request_count += 1
      request.create_timestamp! if needs_request_timestamp?
      request.create_identifier! if needs_request_identifier?
      @before_send_request.call(request) if @before_send_request
      _log_result [ :send_request, :request, request, @request_count ] do
        request_payload = encoder.dup.encode(request)
        opaque_response = _send_request(request, request_payload)
        receive_response opaque_response
      end
    end

    # !SLIDE
    # Transport#receive_request
    # Receive Request payload from stream.
    def receive_request stream
      @request_count ||= 0; @request_count += 1
      _log_result [ :receive_request, :stream, stream, @request_count ] do
        additional_data = { }
        if req_and_state = _receive_request(stream, additional_data)
          req = req_and_state[0] = encoder.dup.decode(req_and_state.first)
          req.additional_data = additional_data if req
        end
        req_and_state
      end
    end
    # !SLIDE END

    # !SLIDE
    # Transport#send_response
    # Send Response to stream.
    def send_response response, stream, request_state
      _log_result [ :receive_request, :response, response, :stream, stream, :request_state, request_state ] do
        @on_response_exception.call(response) if @on_response_exception && response.exception
        response_payload = decoder.dup.encode(response)
        _send_response(response, response_payload, stream, request_state)
      end
    end
    # !SLIDE END

    # !SLIDE
    # Transport#receive_response
    # Receieve Response from stream:
    # * Receive Response payload
    # * Decode Response.
    # * Extract Response result or exception.
    def receive_response opaque_response
      _log_result [ :receive_response ] do
        response_payload = _receive_response opaque_response
        response = decoder.dup.decode(response_payload)
        _log { [ :receive_response, :response, response ] }
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
      request = request_state = request_ok = response = response_ok = exception = nil
      request, request_state = receive_request(in_stream)
      request_ok = true
      response = invoke_request!(request)
      response_ok = true
    rescue Exception => exc
      exception = exc
      _log [ :request_error, exc ]
      @on_exeception.call(exc, :request, request) if @on_exception
    ensure
      if out_stream
        begin
          if request_ok 
            if exception && ! response_ok
              response = Response.new(request, nil, exception)
            end
            send_response(response, out_stream, request_state)
          end
        rescue Exception => exc
          _log [ :response_error, exc ]
          @on_exception.call(exc, :response, response) if @on_exception
        end
      else
        raise exception if exception
      end
    end

    # !SLIDE pause
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

    # Invokes the the Request object, returns a Response object.
    def invoke_request! request
      _log_result [ :invoke_request!, request ] do
        request.invoke!
      end
    end
    # !SLIDE END
    # !SLIDE resume

  end
  # !SLIDE END
end
