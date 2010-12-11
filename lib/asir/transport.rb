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

    # !SLIDE
    # Transport#send_request 
    # * Encode Request.
    # * Send encoded Request.
    # * Decode Response.
    # * Extract result or exception.
    def send_request request
      request.create_identifier! if needs_request_identifier?
      _log_result [ :send_request, :request, request ] do
        request_payload = encoder.dup.encode(request)
        opaque_response = _send_request(request_payload)
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
      _log_result [ :receive_request, :stream, stream ] do
        request_payload = _receive_request(stream)
        encoder.dup.decode(request_payload)
      end
    end
    # !SLIDE END

    # !SLIDE
    # Transport#send_response
    # Send Response to stream.
    def send_response response, stream
      _log_result [ :receive_request, :response, response, :stream, stream ] do
        response_payload = decoder.encode(response)
        _send_response(response_payload, stream)
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
        @response = request.invoke!
      end
    end
    # !SLIDE END
    # !SLIDE resume

    # Transport subclasses.
    # ...
    # !SLIDE pause

    # !SLIDE 
    # Null Transport
    #
    # Never send Request.
    class Null < self
      def _send_request request_payload
        nil
      end
    end
    # !SLIDE END


    # !SLIDE
    # Local Transport
    #
    # Send Request to same process.
    # Requires a Identity Coder.
    class Local < self
      # Returns Response object.
      def _send_request request
        invoke_request!(request)
      end

      # Returns Response object from #_send_request.
      def _receive_response opaque_response
        opaque_response
      end
    end
    # !SLIDE END


    # !SLIDE
    # Subprocess Transport
    #
    # Send one-way Request to a forked subprocess.
    class Subprocess < Local
      def _send_request request
        Process.fork do 
          super
        end
        nil # opaque
      end

      # one-way; no Response
      def _receive_response opaque
        nil
      end
    end
    # !SLIDE END


    # !SLIDE
    # Payload IO for Transport
    #
    # Framing
    # * Line containing the number of bytes in the payload.
    # * The payload bytes.
    # * Blank line.
    module PayloadIO
      def _write payload, stream
        _log { "  _write size = #{payload.size}" }
        stream.puts payload.size
        _log { "  _write #{payload.inspect}" }
        stream.write payload
        stream.puts EMPTY_STRING
        stream.flush
        stream
      end

      def _read stream
        size = stream.readline.chomp.to_i
        _log { "  _read  size = #{size.inspect}" }
        payload = stream.read(size)
        _log { "  _read  #{payload.inspect}" }
        stream.readline
        payload
      end

      # !SLIDE pause
      def close
        @stream.close if @stream
      ensure
        @stream = nil
      end
      # !SLIDE resume
    end

    # !SLIDE
    # Stream Transport
    #
    # Base class handles Requests on stream.
    # Stream Transports require a Coder that encodes to and from String payloads.
    class Stream < self

      # !SLIDE
      # Serve all Requests from a stream.
      def serve_stream! in_stream, out_stream
        until in_stream.eof?
          begin
            serve_stream_request! in_stream, out_stream
          rescue Exception => err
            _log [ :serve_stream_error, err ]
          end
        end
      end

      # !SLIDE
      # Serve a Request from a stream.
      def serve_stream_request! in_stream, out_stream
        serve_request! in_stream, out_stream
      end
    end
  end
  # !SLIDE END
end
