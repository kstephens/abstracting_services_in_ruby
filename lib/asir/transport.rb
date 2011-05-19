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

    # Proc to call with exception, if exception occurs within #serve_request!
    # on.error(exception, :request, Request_instance)
    # or.error(exception, :response, Response_instance)
    attr_accessor :on_error

    # !SLIDE
    # Transport#send_request 
    # * Encode Request.
    # * Send encoded Request.
    # * Decode Response.
    # * Extract result or exception.
    def send_request request
      @request_count ||= 0; @request_count += 1
      request.create_identifier! if needs_request_identifier?
      _log_result [ :send_request, :request, request, @request_count ] do
        request_payload = encoder.dup.encode(request)
        opaque_response = _send_request(request, request_payload)
        response = receive_response opaque_response
        _log { [ :send_request, :response, response ] }
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

    # !SLIDE
    # Transport#receive_request
    # Receive Request payload from stream.
    def receive_request stream
      @request_count ||= 0; @request_count += 1
      _log_result [ :receive_request, :stream, stream, @request_count ] do
        additional_data = { }
        request_payload = _receive_request(stream, additional_data)
        request = encoder.dup.decode(request_payload)
        request.additional_data = additional_data if request 
        request
      end
    end
    # !SLIDE END

    # !SLIDE
    # Transport#send_response
    # Send Response to stream.
    def send_response response, stream
      _log_result [ :receive_request, :response, response, :stream, stream ] do
        response_payload = decoder.encode(response)
        _send_response(response, response_payload, stream)
      end
    end
    # !SLIDE END

    # !SLIDE
    # Transport#receive_response
    # Receieve Response from stream.
    def receive_response opaque_response
      _log_result [ :receive_response ] do
        response_payload = _receive_response opaque_response
        decoder.decode(response_payload)
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
      request = request_ok = response = response_ok = exception = nil
      request = receive_request(in_stream)
      request_ok = true
      response = invoke_request!(request)
      response_ok = true
    rescue Exception => exc
      exception = exc
      _log [ :request_error, exc ]
      @on_error.call(exc, :request, request) if @on_error
    ensure
      if out_stream
        begin
          if request_ok 
            if exception && ! response_ok
              response = Response.new(request, nil, exception)
            end
            send_response(response, out_stream)
          end
        rescue Exception => exc
          _log [ :response_error, exc ]
          @on_error.call(exc, :response, response) if @on_error
        end
      else
        raise exception if exception
      end
    end

    # !SLIDE pause
    # !SLIDE
    # Transport Support
    # ...

    def needs_request_identifier?
      false
    end

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
