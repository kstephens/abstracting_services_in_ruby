require 'yaml'
require 'digest/sha1'
require 'socket'

# !SLIDE
# Abstracting Services in Ruby
#
# * Kurt Stephens
# * 2010/09/30 DRAFT
# * Slides -- "":http://kurtstephens.com/pub/abstracting_services_in_ruby/asir.slides/
# * Code -- "":http://kurtstephens.com/pub/abstracting_services_in_ruby/
# * Git -- "":http://github.com/kstephens/abstracting_services_in_ruby
# * Tools 
# ** Riterate -- "":http://github.com/kstephens/riterate
# ** Scarlet -- "":http://github.com/kstephens/scarlet
#
# !SLIDE END

# !SLIDE
# Issues
#
# * Problem Domain .vs. Solution Domain
# ** Client knows too much about infrastructure.
# ** Evaluating and switching infrastructures.
# * Service Semantics
# ** One-way (no response after request) .vs. Two-way
# ** Synchronous .vs. Asynchronous
# * Testing, Debugging, Diagnostics
# ** Setup for testing and QA is more complex.
# ** Measuring test coverage of remote services.
# ** Debugging the root cause of remote service errors.
# ** Diagnostic hooks.
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
# * Nouns:
# ** Service -> Module
# ** Client -> Just a Ruby caller
# ** Proxy
# ** Request, Response, Exception
# ** Transport
# ** Encoder, Decoder -> Coder
# ** Logging
# * Verbs:
# ** Intercept Request -> Proxy
# ** Invoke Request    -> Request
# ** Invoke Exception
# ** Send Request, Recieve Request -> Transport
# ** Encode Object, Decode Object -> Coder
#
# !SLIDE END

# !SLIDE
# Modules and Classes
module ASIR
  # Reusable constants to avoid unnecessary garbage.
  EMPTY_ARRAY = [ ].freeze; EMPTY_HASH =  { }.freeze; EMPTY_STRING = ''.freeze

  # Generic API error.
  class Error < ::Exception; end

  # !SLIDE
  # Object Initialization
  #
  # Support initialization by Hash.
  #
  # E.g.:
  # @@@
  #   Foo.new(:bar => 1, :baz => 2)
  # @@@
  # =>
  # @@@
  #   obj = Foo.new; obj.bar = 1; obj.baz = 2; obj
  # @@@
  module Initialization
    def initialize opts = nil
      opts ||= EMPTY_HASH
      initialize_before_opts if respond_to? :initialize_before_opts
      opts.each do | k, v |
        send(:"#{k}=", v)
      end
      initialize_after_opts if respond_to? :initialize_after_opts
    end
  end


  # !SLIDE
  # Diagnostic Logging
  #
  # Logging mixin.
  module Log
    def _log msg = nil
      msg ||= yield
      msg = String === msg ? msg : _log_format(msg)
      msg = "  #{$$} #{Module === self ? self : self.class} #{msg}"
      case @logger
      when Proc
        @logger.call msg
      when IO
        @logger.puts msg
      else
        $stderr.puts msg if $_log_verbose
      end
    end

    def _log_result msg
      msg = String === msg ? msg : _log_format(msg)
      _log { "#{msg} => ..." }
      result = yield
      _log { "#{msg} => \n    #{result.inspect}" }
      result
    end

    def _log_format obj
      case obj
      when Exception
        "#{obj.inspect}\n    #{obj.backtrace * "\n    "}"
      when Array
        obj.map { | x | _log_format x } * ", "
      else
        obj.inspect
      end
    end
  end


  # !SLIDE
  # Request
  #
  # Encapsulate the request message from the Client to be handled by the Service.
  class Request
    attr_accessor :receiver, :receiver_class, :selector, :arguments, :result
    attr_accessor :identifier, :client, :timestamp # optional

    def initialize r, s, a
      @receiver, @selector, @arguments = r, s, a
      @receiver_class = @receiver.class
    end

    def invoke!
      Response.new(self, @result = @receiver.__send__(@selector, *@arguments))
    rescue Exception => exc
      Response.new(self, nil, EncapsulatedException.new(exc))
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

    def dereference_receiver!
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

    def reference_receiver!
      if String === @receiver_class
        @receiver_class = eval("::#{@receiver_class}")
        @receiver = eval("::#{@receiver}")
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
      @request, @result, @exception = req, res, exc
    end
  end

  # !SLIDE
  # Encapsulated Exception
  #
  # Encapsulates exceptions raised in the Service.
  class EncapsulatedException
    attr_accessor :exception_class, :exception_message, :exception_backtrace

    def initialize exc
      @exception_class     = exc.class.name
      @exception_message   = exc.message
      @exception_backtrace = exc.backtrace
    end

    def invoke!
      raise eval("::#{@exception_class}"), @exception_message, @exception_backtrace
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
    # Marshal Coder
    # Use Ruby Marshal for encode/decode.
    class Marshal < self
      def _encode obj
        ::Marshal.dump(obj)
      end

      def _decode obj
        ::Marshal.load(obj)
      end
    end


    # !SLIDE
    # YAML Coder
    # Use YAML for encode/decode.
    class Yaml < self
      def _encode obj
        case obj
        when Request
          obj = obj.dereference_receiver!
        end
        ::YAML::dump(obj)
      end

      def _decode obj
        case obj = ::YAML::load(obj)
        when Request
          obj.reference_receiver!
        else
          obj
        end
      end
    end


    # !SLIDE
    # Other Coders

    # Encode as XML.
    class XML < self
      # ...
    end


    # Encode as JSON.
    class JSON < self
      # ...
    end


    # !SLIDE
    # Multi Coder
    # Chain multiple Coders as one.
    #
    # @@@
    #   request  --> | e1 | --> | e2 | --> | eN | --> 
    #   response <-- | d1 | <-- | d2 | <-- | dN | <--
    # @@@
    class Multi < self
      attr_accessor :encoders

      def _encode obj
        encoders.each do | e |
          obj = e.encode(obj)
        end
        obj
      end

      def _decode obj
        encoders.reverse.each do | e |
          obj = e.decode(obj)
        end
        obj
      end
    end
    # !SLIDE END

    # !SLIDE
    # Sign Coder
    #
    # Sign payload during encode, check signature during decode.
    #
    # Signature is the digest of secret + payload.
    #
    # Encode payload as Hash containing the digest function name, signature and payload.
    # Decode and validate Hash containing the digest function name, signature and payload.
    #
    class Sign < self
      attr_accessor :secret, :function

      def _encode obj
        payload = obj.to_s
        { 
          :function => function,
          :signature => ::Digest.const_get(function).
                          new.hexdigest(secret + payload),
          :payload => payload,
        }
      end

      def _decode obj
        raise SignatureError, "expected Hash, given #{obj.class}" unless Hash === obj
        payload = obj[:payload]
        raise SignatureError, "signature invalid" unless obj == _encode(payload)
        payload
      end

      # !SLIDE
      # Sign Coder Support

      # Signature Error.
      class SignatureError < Error; end

      def initialize_before_opts
        @function = :SHA1
      end
      # !SLIDE END
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
        request_payload = encoder.encode(request)
        opaque = _send_request(request_payload)
        response = receive_response opaque
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
        encoder.decode(request_payload)
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
    def receive_response opaque
      _log_result [ :receive_response ] do
        response_payload = _receive_response opaque
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
      def _send_request request
        nil
      end
    end
    # !SLIDE END


    # !SLIDE
    # Local Transport
    #
    # Send Request to same process.
    class Local < self
      # Returns Response object.
      def _send_request request
        invoke_request!(request)
      end

      # Returns Response object from #_send_request.
      def _receive_response opaque
        opaque
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
        stream.puts payload.size
        stream.write payload
        stream.puts EMPTY_STRING
        _log { "  _write #{payload.inspect}" }
        stream.flush
      end

      def _read stream
        size = stream.readline.chomp.to_i
        _log { "  _read size    = #{size.inspect}" }
        payload = stream.read(size)
        _log { "  _read payload = #{payload.inspect}" }
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
        request = request_ok = result = result_ok = exception = nil
        request = receive_request(in_stream)
        request_ok = true
        result = invoke_request!(request)
        result_ok = true
      rescue Exception => exc
        exception = exc
        _log [ :request_error, exc ]
      ensure
        if out_stream
          begin
            if request_ok 
              if exception && ! result_ok
                result = EncapsulatedException.new(exception)
              end
              send_response(result, out_stream)
            end
          rescue Exception => exc
            _log [ :response_error, exc ]
          end
        else
          raise exception if exception
        end
      end
    end


    # !SLIDE
    # File Transport
    #
    # Send Request one-way to a file.
    # Can be used as a log or named pipe service.
    class File < Stream
      include PayloadIO # send, recv

      attr_accessor :file, :stream

      def _send_request request
        _write request, stream
      ensure
        close if ::File.pipe?(file)
      end

      def _receive_request stream
        _read stream
      end

      # one-way; no Response
      def _send_response stream
        nil
      end

      # one-way; no Response
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

      def service_file!
        ::File.open(file, "r") do | stream |
          serve_stream! stream, nil
        end
      end

      # !SLIDE
      # Named Pipe Server

      def prepare_fifo_server!
        _log :prepare_fifo_server!
        unless ::File.exist? file
          system(cmd = "mkfifo #{file.inspect}") || (raise "cannot run #{cmd.inspect}")
          system(cmd = "chmod 666 #{file.inspect}") || (raise "cannot run #{cmd.inspect}")
        end
      end

      def run_fifo_server!
        _log :run_fifo_server!
        @running = true
        while @running
          service_file!
        end
      end

      # !SLIDE END
    end


    # !SLIDE
    # TCP Socket Transport
    class TcpSocket < Stream
      include PayloadIO
      attr_accessor :port, :address
      
      # !SLIDE
      # Returns a connected TCP socket.
      def stream 
        @stream ||=
          begin
            addr = address || '127.0.0.1'
            _log { "connect #{addr}:#{port}" }
            sock = TCPSocket.open(addr, port)
            sock
          rescue Exception => err
            raise Error, "Cannot connect to #{addr}:#{port}: #{err.inspect}", err.backtrace
          end
      end

      # !SLIDE
      # Sends the encoded Request payload.
      def _send_request request_payload
        _write request_payload, stream
      end

      # !SLIDE
      # Receives the encoded Request payload.
      def _receive_request stream
        _read stream
      end

      # !SLIDE
      # Sends the encoded Response payload.
      def _send_response response_payload, stream
        _write response_payload, stream
      end

      # !SLIDE
      # Receives the encoded Response payload.
      def _receive_response opaque
        _read stream
      end

      # !SLIDE
      # TCP Socket Server

      def prepare_socket_server!
        _log { "prepare_socket_server! #{port}" }
        @server = TCPServer.open(port)
      end

      def run_socket_server!
        _log :run_socket_server!
        @running = true
        while @running
          stream = @server.accept
          _log { "run_socket_server!: connected" }
          begin
            # Same socket for both in and out stream.
            serve_stream! stream, stream
          ensure
            stream.close
          end
          _log { "run_socket_server!: disconnected" }
        end
      end

    end
    # !SLIDE END


    # !SLIDE
    # HTTP Transport
    #
    # Send to an HTTP server.
    class HTTP < self
      attr_accessor :uri

      def _send_request request
        # ...
      end
    end
    # !SLIDE END


    # !SLIDE
    # Multi Transport
    #
    # Send to multiple Transports.
    class Multi < self
      attr_accessor :transports

      def _send_request request
        result = nil
        transports.each do | transport |
          result = transport.send_request(request)
        end
        result
      end

      def needs_request_identifier?
        transports.any? { | t | needs_request_identifier? }
      end
    end
    # !SLIDE END

    # !SLIDE resume
  end
  # !SLIDE END


  # !SLIDE
  # Mixin Client support to any Module
  #
  # Extend Module with #client proxy support.
  module Client
    def self.included target
      super
      target.extend ModuleMethods if Module === target
    end
    
    module ModuleMethods
      def client
        @client ||=
          ASIR::Client::Proxy.new(:receiver => self)
      end
    end

    # !SLIDE
    # Client Proxy
    #
    # Provide client interface proxy to a service.
    class Proxy
      include Log, Initialization
      
      attr_accessor :receiver, :transport
      
      def transport
        @transport ||=
          Transport::Local.new
      end
      
      # Accept all other messages to be encoded and transported to a service.
      def method_missing selector, *arguments
        raise ArgumentError, "block given" if block_given?
        _log { "method_missing #{selector.inspect} #{arguments.inspect}" }
        request = Request.new(receiver, selector, arguments)
        result = transport.send_request(request)
        result
      end
    end
    # !SLIDE END
  end
  # !SLIDE END
end
# !SLIDE END

# !SLIDE
# Synopsis
#
# * Services are easy to abstract away.
# * Separation of transport, encoding.
# * One-way .vs. Two-way.
# * Asynchronous .vs. synchronous.
#
# !SLIDE END

