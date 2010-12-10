# !SLIDE
# Abstracting Services in Ruby
#
# * Kurt Stephens
# * Enova Financial
# * 2010/12/03
# * Slides -- "":http://kurtstephens.com/pub/ruby/abstracting_services_in_ruby/asir.slides/
# * Code -- "":http://kurtstephens.com/pub/ruby/abstracting_services_in_ruby/
# * Git -- "":http://github.com/kstephens/abstracting_services_in_ruby
# * Tools 
# ** Riterate -- "":http://github.com/kstephens/riterate
# ** Scarlet -- "":http://github.com/kstephens/scarlet
#
# !SLIDE END

# !SLIDE
# Issues
#
# * Problem Domain, Solution Domain
# * Service Middleware Semantics
# * Testing, Debugging, Diagnostics
# * Productivity
#
# !SLIDE END

# !SLIDE
# Problem Domain, Solution Domain
#
# * Client knows too much about infrastructure.
# * Evaluating and switching infrastructures.
#
# !SLIDE END

# !SLIDE
# Service Middleware Semantics
#
# * Directionality: One-way, Two-way
# * Synchronicity: Synchronous, Asynchronous
# * Distribution: Local Process, Local Thread, Distributed
# * Robustness: Retry, Replay, Fallback
#
# !SLIDE END

# !SLIDE
# Testing, Debugging, Diagnostics
#
# * Configuration for testing and QA is more complex.
# * Measuring test coverage of remote services.
# * Debugging the root cause of remote service errors.
# * Diagnostic hooks.
#
# !SLIDE END

# !SLIDE
# Objectives
#
# * Simplify service/client definitions and interfaces.
# * Anticipate new encoding, delivery and security requirements.
# * Compose encoding and transport concerns.
# * Elide deployment decisions.
# * Integrate diagnostics and logging.
# * Simplify testing.
#
# !SLIDE END

# !SLIDE
# Design
#
# * Nouns -> Objects -> Classes
# * Verbs -> Responsibilities -> Methods
#
# h3. Book: "Designing Object-Oriented Software"
#  * Wirfs-Brock, Wilkerson, Wiener
#
# !SLIDE END

# !SLIDE
# Design: Nouns
#
# * Service -> Module
# * Client -> Just a Ruby caller
# * Proxy
# * Request
# * Response, Exception (two-way)
# * Transport -> (file, pipe, http, queue, ActiveResource)
# * Encoder, Decoder -> Coder (Marshal, XML, JSON, ActiveResource)
# * Logging
#
# !SLIDE END

# !SLIDE
# Design: Verbs
#
# * Intercept Request -> Proxy
# * Invoke Request    -> Request
# * Invoke Exception
# * Send Request, Recieve Request -> Transport
# * Encode Object, Decode Object -> Coder
#
# !SLIDE END

# !SLIDE
# Simple
#
# !PIC BEGIN
# 
# box "Client" "(CustomersController" "#send_invoice)"; arrow; 
# ellipse "Send" "Request" "(Ruby message)"; arrow; 
# box "Service" "(Email.send_email)";
#
# !PIC END
#
# !SLIDE END

# !SLIDE
# Client-Side Request
#
# !PIC BEGIN
# box "Client"; arrow; 
# ellipse "Proxy"; arrow; 
# ellipse "Create" "Request"; arrow; 
# ellipse "Encode" "Request"; arrow; 
# ellipse "Send" "Request";
# line; down; arrow;
# !PIC END
#
# !SLIDE END

# !SLIDE
# Server-Side
#
# !PIC BEGIN
# down; line; right; arrow; 
# ellipse "Receive" "Request"; arrow; 
# ellipse "Decode" "Request"; arrow; 
# ellipse "Request"; 
# line; down; arrow; 
# IR: ellipse "Invoke" "Request";
# right; move; move;
# Service: box "Service" with .w at IR.e + (movewid, 0); 
# arrow <-> from IR.e to Service.w;
# move to IR.s; down; line;
# left; arrow; 
# ellipse "Create" "Response"; arrow; 
# ellipse "Encode" "Response"; arrow;
# ellipse "Send" "Response"; 
# line; down; arrow
# !PIC END
#
# !SLIDE END

# !SLIDE
# Client-Side Response
#
# !PIC BEGIN
# down; line; left; arrow;
# ellipse "Receive" "Response"; arrow; 
# ellipse "Decode" "Response"; arrow; 
# ellipse "Response"; arrow; 
# ellipse "Proxy"; arrow; 
# box "Client";
# !PIC END
#
# !SLIDE END

require 'asir/log'
require 'asir/initialization'

# !SLIDE
# Modules and Classes
module ASIR
  # Reusable constants to avoid unnecessary garbage.
  EMPTY_ARRAY = [ ].freeze; EMPTY_HASH =  { }.freeze; EMPTY_STRING = ''.freeze
  MODULE_SEP = '::'.freeze

  # Generic API error.
  class Error < ::Exception; end

  # !SLIDE
  # Object Resolving
  #
  module ObjectResolving
    class ResolveError < Error; end
    def resolve_object name
      name.to_s.split(MODULE_SEP).inject(Object){|m, n| m.const_get(n)}
    rescue Exception => err
      raise ResolveError, "cannot resolve #{name.inspect}: #{err.inspect}", err.backtrace
    end
  end

  # !SLIDE
  # Request
  #
  # Encapsulate the request message from the Client to be handled by the Service.
  class Request
    include ObjectResolving
    attr_accessor :receiver, :receiver_class, :selector, :arguments, :result
    attr_accessor :identifier, :client, :timestamp # optional

    def initialize r, s, a
      @receiver, @selector, @arguments = r, s, a
      @receiver_class = @receiver.class
    end

    def invoke!
      Response.new(self, @result = @receiver.__send__(@selector, *@arguments))
    rescue Exception => exc
      Response.new(self, nil, exc)
    end

    # !SLIDE
    # Request Identifier

    def create_identifier!
      @identifier ||= 
        [
          @@counter += 1,
          $$,
          Thread.current.object_id,
          @@uuid ||= File.read("/proc/sys/kernel/random/uuid").chomp!
        ] * '-'
    end
    @@counter ||= 0; @@uuid ||= nil

    # !SLIDE
    # Help encode/decode receiver

    def encode_receiver!
      unless String === @receiver_class
        case @receiver
        when Module
          obj = self.dup
          obj.receiver = @receiver.name
          obj.receiver_class = @receiver_class.name
          return obj
        end
      end
      self
    end

    def decode_receiver!
      if String === @receiver_class
        @receiver_class = resolve_object(@receiver_class)
        @receiver = resolve_object(@receiver)
        unless @receiver_class === @receiver
          raise Error, "receiver #{@receiver.class.name} is not a #{@receiver_class}" 
        end
      end
      self
    end
    # !SLIDE END
  end

  # !SLIDE
  # Response
  #
  # Encapsulate the response returned to the Client.
  class Response
    attr_accessor :request, :result, :exception
    attr_accessor :identifier, :server, :timestamp # optional

    def initialize req, res = nil, exc = nil
      @request, @result, @exception = req, res, (exc && EncapsulatedException.new(exc))
    end
  end

  # !SLIDE
  # Encapsulated Exception
  #
  # Encapsulates exceptions raised in the Service.
  class EncapsulatedException
    include ObjectResolving
    attr_accessor :exception_class, :exception_message, :exception_backtrace

    def initialize exc
      @exception_class     = exc.class.name
      @exception_message   = exc.message
      @exception_backtrace = exc.backtrace
    end

    def invoke!
      raise resolve_object(@exception_class), @exception_message, @exception_backtrace
    end
  end

  # !SLIDE
  # Coder 
  #
  # Define encoding and decoding for Requests and Responses along a Transport.
  class Coder
    include Log, Initialization

    def encode obj
      _log_result [ :encode, obj ] do
        _encode obj
      end
    end

    def decode obj
      _log_result [ :decode, obj ] do
        obj and _decode obj
      end
    end

    def _subclass_responsibility *args
      raise "subclass responsibility"
    end
    alias :_encode :_subclass_responsibility
    alias :_decode :_subclass_responsibility


    # Coder subclasses.
    # ...
    # !SLIDE pause

    # !SLIDE 
    # Null Coder
    # Always encode/decode as nil.
    class Null < self
      def _encode obj
        nil
      end

      def _decode obj
        nil
      end
    end


    # !SLIDE
    # Identity Coder
    # Perform no encode/decode.
    class Identity < self
      def _encode obj
        obj
      end

      def _decode obj
        obj
      end
    end


    # !SLIDE
    # Chain Coder
    # Chain multiple Coders as one.
    #
    # @@@
    #   request  --> | e1 | --> | e2 | --> | eN | --> 
    #   response <-- | d1 | <-- | d2 | <-- | dN | <--
    # @@@
    class Chain < self
      attr_accessor :encoders

      def _encode obj
        encoders.each do | e |
          obj = e.dup.encode(obj)
        end
        obj
      end

      def _decode obj
        encoders.reverse_each do | e |
          obj = e.dup.decode(obj)
        end
        obj
      end
    end
    # !SLIDE END

    # !SLIDE resume
  end
  # !SLIDE END


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

    # !SLIDE
    # File Transport
    #
    # Send Request one-way to a file.
    # Can be used as a log or named pipe service.
    class File < Stream
      include PayloadIO # _write, _read

      attr_accessor :file, :stream

      # Writes a Request payload String.
      def _send_request request_payload
        _write request_payload, stream
      ensure
        close if ::File.pipe?(file)
      end

      # Returns a Request payload String.
      def _receive_request stream
        _read stream
      end

      # one-way; no Response.
      def _send_response stream
        nil
      end

      # one-way; no Response.
      def _receive_response opaque
        nil
      end

      # !SLIDE
      # File Transport Support
    
      def stream
        @stream ||=
          ::File.open(file, "w+")
      end

      # !SLIDE
      # Process (receive) requests from a file.

      def serve_file!
        ::File.open(file, "r") do | stream |
          serve_stream! stream, nil
        end
      end

      # !SLIDE
      # Named Pipe Server

      def prepare_pipe_server!
        _log :prepare_pipe_server!
        unless ::File.exist? file
          system(cmd = "mkfifo #{file.inspect}") or raise "cannot run #{cmd.inspect}"
        end
      end

      def run_pipe_server!
        _log :run_pipe_server!
        @running = true
        while @running
          serve_file!
        end
      end

      # !SLIDE END
    end


    # !SLIDE
    # Fallback Transport
    class Fallback < self
      attr_accessor :transports

      def send_request request
        result = sent = exceptions = nil
        transports.each do | transport |
          begin
            _log { [ :send_request, :transport, transport ] }
            result = transport.send_request request
            sent = true
            break
          rescue ::Exception => exc
            (exceptions ||= [ ]) << [ transport, exc ]
            _log { [ :send_request, :transport_failed, transport, exc ] }
          end
        end
        unless sent
          _log { [ :send_request, :fallback_failed, exceptions ] }
          raise FallbackError, "fallback failed"
        end
        result
      end
      class FallbackError < Error; end
    end
    # !SLIDE END

    # !SLIDE
    # Broadcast Transport
    #
    # Broadcast to multiple Transports.
    class Broadcast < self
      attr_accessor :transports

      def _send_request request
        result = nil
        transports.each do | transport |
          _log { [ :send_request, :transport, transport ] }
          result = transport.send_request(request)
        end
        result
      end

      def _receive_response opaque
        opaque
      end

      def needs_request_identifier?
        transports.any? { | t | t.needs_request_identifier? }
      end
    end
    # !SLIDE END

    # !SLIDE resume
  end
  # !SLIDE END
end
# !SLIDE END

require 'asir/client'

# !SLIDE
# Synopsis
#
# * Services are easy to abstract away.
# * Separation of transport, encoding.
# * 
#
# !SLIDE END


