require 'yaml'
require 'digest/sha1'
require 'gserver'
require 'socket'

# !SLIDE :index 1
# Abstracting Services in Ruby
#
# * Kurt Stephens
# * http://kurtstephens.com/pub/abstracting_service_in_ruby/
#
# !SLIDE END

# !SLIDE :index 2
# Objectives
#
# * Simplify service/client definitions.
# * Anticipate new encoding, delivery and security requirements.
# * Separate request/response encoding and delivery for composition.
# * Elide deployment decisions.
# * Integrate diagnostics and logging.
# * Simplify integration testing.
#
# !SLIDE END

# !SLIDE :index 3
# Design
#
# * Nouns:
# ** Service
# ** Client
# ** Proxy
# ** Request
# ** Response
# ** Transport
# ** Encoder \__ Coder
# ** Decoder /
# ** Logging
# * Verbs:
# ** Intercept Request
# ** Initiate Transport
# ** Deliver Request  \__ Transport
# ** Receive Response /
# ** Encode Object    \__ Coder
# ** Decode Object    /
#
# !SLIDE END

# !SLIDE :index 4
# Modules and Classes
module SI
  # Reusable constants to avoid unncessary garbage.
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
      msg = "  *** #{$$} #{Module === self ? self : self.class} #{msg}"
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
      _log { "#{msg} => #{result.inspect}" }
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


  # !SLIDE :index 5
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
      @result = @receiver.__send__(@selector, *@arguments)
    rescue Exception => exc
      EncapsulatedException.new(exc).denormalize!
    end

    def create_identifier!
      @identifier ||= File.read("/proc/sys/kernel/random/uuid").chomp!
    end
  end

  # !SLIDE :index 7
  # Response
  #
  # Encapsulate the response returned to the Client.
  class Response
    attr_accessor :request, :result

    def initialize req, res = nil
      @request, @result = req, res
    end
  end

  # !SLIDE :index 6
  # Encapsulated Exception
  #
  # Wrapper for exceptions raised in the Service.
  class EncapsulatedException
    attr_accessor :exception, :exception_class, :exception_message, :exception_backtrace

    def initialize exc
      @exception = exc
    end

    def denormalize!
      if @exception
        @exception_class = @exception.class
        @exception_message = @exception.message
        @exception_backtrace = @exception.backtrace
        @exception = nil
      end
      self
    end

    def invoke!
      if @exception
        raise @exception
      else
        raise @exception_class, @exception_message, @exception_backtrace
      end
    end
  end

  # !SLIDE :index 8
  # Coder 
  #
  # Define encoding and decoding for Requests and Responses along a Transport.
  class Coder
    include Log
    include Initialization

    def encode obj
      _log_result [ :encode, obj ] do
        _encode obj
      end
    end

    def decode obj
      _log_result [ :decode, obj ] do
        _decode obj
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


    # !SLIDE :index 310
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


    # !SLIDE :index 730
    # Marshal Coder
    # Use Ruby Marshal for encode/decode.
    class Marshal < self
      def _encode obj
        ::Marshal.dump(obj)
      end

      def _decode obj
        return obj unless obj
        ::Marshal.load(obj)
      end
    end


    # !SLIDE :index 520
    # YAML Coder
    # Use YAML for encode/decode.
    class Yaml < self
      def _encode obj
        case obj
        when Request
          case obj.receiver
          when Module
            obj = obj.dup
            obj.receiver = obj.receiver.name
            obj.receiver_class = obj.receiver_class.name
          end
        end
        ::YAML::dump(obj)
      end

      def _decode obj
        return obj unless obj
        obj = ::YAML::load(obj)
        case obj
        when Request
          case obj.receiver_class
          when 'Module', 'Class'
            obj.receiver = eval("::#{obj.receiver}")
            obj.receiver_class = eval("::#{obj.receiver_class}")
          end
        end
        obj
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


    # !SLIDE :index 710
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

    # !SLIDE :index 730
    # Security Coder
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
        return obj unless obj
        raise SignatureError, "expected Hash, given #{obj.class}" unless Hash === obj
        payload = obj[:payload]
        raise SignatureError, "signature invalid" unless obj == _encode(payload)
        payload
      end

      # !SLIDE :index 731
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


  # !SLIDE :index 9
  # Transport
  #
  # Client: Deliver a Request to the Service.
  # Service: Receive the Request from the Client.
  # Service: Invoke the Request.
  # Service: Transport a Response to the Client.
  # Client: Receive the Response from the Service.
  class Transport
    include Log
    include Initialization

    attr_accessor :encoder, :decoder

    # !SLIDE :index 10
    # Transport#deliver 
    # Encode request, deliver, decode result.
    def deliver request
      result = nil

      request.create_identifier! if needs_request_identifier?

      _log_result [ :deliver, request ] do
        request = encoder.encode(request)
        result = _deliver(request)
        result = decoder.decode(result)
        if EncapsulatedException === result
          result.invoke!
        end
      end
    
      result
    end

    # !SLIDE :index 10
    # Transport#receive
    # Receive request payload from port
    def receive port
      _log_result [ :receive, port ] do
        request_payload = _receive(port)
        request = encoder.decode(request_payload)
      end
    end
    # !SLIDE END

    def _subclass_responsibility *args
      raise "subclass responsibility"
    end
    alias :_deliver :_subclass_responsibility
    alias :_receive :_subclass_responsibility

    # !SLIDE pause
    # !SLIDE :index 11
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
      _log_result [ :invoke!, request ] do
        request.invoke!
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
    # Never deliver.
    class Null < self
      def _deliver request
        nil
      end
    end
    # !SLIDE END


    # !SLIDE :index 320
    # Local Transport
    #
    # Deliver to same process.
    class Local < self
      def _deliver request
        request.invoke!
      end
    end
    # !SLIDE END


    # !SLIDE :index 410
    # Subprocess Transport
    #
    # Deliver to a forked subprocess.
    class Subprocess < Local
      def _deliver request
        Process.fork do 
          super
        end
        nil
      end

      def needs_request_identifier?; true; end
    end
    # !SLIDE END


    # !SLIDE :index 520
    # Payload IO for Transport
    #
    # * Line containing the number of bytes in the payload
    # * The payload
    # * Blank line
    module PayloadIO
      def _write payload, port
        port.puts payload.size
        port.write payload
        port.puts EMPTY_STRING
        _log { "  _write #{payload.inspect}" }
        port.flush
      end

      def _read port
        size = port.readline.chomp.to_i
        _log { "  _read size    = #{size.inspect}" }
        payload = port.read(size)
        _log { "  _read payload = #{payload.inspect}" }
        port.readline
        payload
      end

      def close
        if @io
          @io.close 
          @io = nil
        end
      end
    end

    # !SLIDE :index 510
    # File Transport
    #
    # Deliver to a file.
    # Can be used as a log or named pipe service.
    class File < self
      include PayloadIO # send, recv

      attr_accessor :file, :io

      def _deliver request
        _write request, io
        close if ::File.pipe?(file)
        nil
      end

      def _receive port
        _read port
      end

      # !SLIDE :index 513
      # File Transport Support
    
      def io
        @io ||=
          ::File.open(file, "w+")
      end

      # !SLIDE :index 560
      # Process (recieve) requests from a file.

      def service_file!
        ::File.open(file, "r") do | port |
          service_port! port
        end
      end

      def service_port! port
        until port.eof?
          begin
            request = receive(port)
            result = invoke_request! request
            # Nowhere to send the result!
          rescue Exception => err
            _log [ :server_error, err ]
          end
        end
      end

      # !SLIDE :index 611
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


    # !SLIDE :index 910
    # TCP Socket Transport
    class TcpSocket < self
      include PayloadIO
      attr_accessor :port, :address
      
      def io 
        @io ||=
          begin
            addr = address || '127.0.0.1'
            _log { "connect #{addr}:#{port}" }
            sock = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
            sockaddr = Socket.pack_sockaddr_in(port, addr)
            sock.connect(sockaddr)
            sock
          rescue Exception => err
            raise Error, "Cannot connect to #{addr}:#{port}: #{err.inspect}", err.backtrace
          end
      end

      def _deliver request
        _write request, io
        _read io
      end

      def _receive port
        _read port
      end

      # !SLIDE :index 920
      # TCP Socket Server

      def prepare_socket_server!
        addr = address || '0.0.0.0'
        _log { "prepare_socket_server! #{addr}:#{port}" }
        @server = Server.new(self, port, addr)
      end

      def run_socket_server!
        _log :run_socket_server!
        @running = true
        while @running
          _log { "run_socket_server! running" }
          @server.start
          @server.tcpServerThread.join
        end
      end

      class ::GServer
        attr_reader :tcpServerThread
      end

      class Server < GServer
        include PayloadIO

        def initialize transport, *args
          @transport = transport
          @mutex = Mutex.new
          super *args
        end

        def serve port 
          @transport._log {" serve: connected" }
          
          @mutex.synchronize do
            begin
              request = request_ok = result = result_ok = exception = nil
              request = @transport.receive(port)
              request_ok = true
              result = @transport.invoke_request!(request)
              result_ok = true
            rescue Exception => exc
              exception = exc
              @transport._log [ :request_error, exc ]
            ensure
              begin
                if request_ok 
                  unless result_ok
                    result = EncapsulatedException.new(exception).denormalize!
                  end
                  @transport._write(@transport.encoder.encode(result), port)
                end
              rescue Exception => exc
                @transport._log [ :response_error, exc ]
              end
            end
          end

          @transport._log { "serve: disconnected" }
        end
 
      end

      # !SLIDE END
    end


    # !SLIDE
    # HTTP Transport
    #
    # Deliver to an HTTP server.
    class HTTP < self
      attr_accessor :uri

      def _deliver request
        # ...
      end
    end
    # !SLIDE END


    # !SLIDE
    # Multi Transport
    #
    # Deliver via multiple Transports.
    class Multi < self
      attr_accessor :transports

      def _deliver request
        result = nil
        transports.each do | transport |
          result = transport.deliver(transport)
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


  # !SLIDE :index 302
  # Mixin Client support to any Module
  #
  # Extend Module with #client proxy support.
  module Client
    def self.included target
      super target
      target.extend ClassMethods
    end
    
    module ClassMethods
      def client
        @client ||=
          SI::Client::Proxy.new(:receiver => self)
      end
    end

    # !SLIDE :index 303
    # Client Proxy
    #
    # Provide client interface proxy to a service.
    class Proxy
      include Log
      include Initialization
      
      attr_accessor :receiver, :transport
      
      def transport
        @transport ||=
          Transport::Local.new
      end
      
      # Accept all other messages to be encoded and transported to a service.
      def method_missing selector, *arguments
        raise ArgumentError, "block given" if block_given?
        _log { "method_missing #{selector.inspect} #{arguments.inspect}" }
        message = Request.new(receiver, selector, arguments)
        result = transport.deliver(message)
        result
      end
    end
    # !SLIDE END
  end
  # !SLIDE END
end
# !SLIDE END


=begin
# !SLIDE :index 100
# Sample Service
#
module SomeService
  def do_it x, y
    x * y + 42
  end
  def do_raise msg
    raise msg
  end
  extend self
end

SomeService.do_it(1, 2)
# !SLIDE END
=end


# !SLIDE :index 200
# Sample Service
# 
# Added logging and #client support.
module SomeService
  include SI::Client
  include SI::Log

  def do_it x, y
    _log_result [ :do_it, x, y ] do 
      x * y + 42
    end
  end
  def do_raise msg
    raise msg
  end
  extend self
end
# !SLIDE END

# Sample client support
#

require 'pp'

$_log_verbose = true
def pr result
  puts PP.pp([ :result, result ], '')
end

# !SLIDE :index 102 :capture_code_output true
# Call service directly
pr SomeService.do_it(1, 2)

# !SLIDE :index 301 :capture_code_output true
# In-core, in-process service
pr SomeService.client.do_it(1, 2)

# !SLIDE :index 401 :capture_code_output true
# One-way, asynchronous subprocess service
begin
SomeService.client.transport = SI::Transport::Subprocess.new

pr SomeService.client.do_it(1, 2)
end

# !SLIDE :index 501 :capture_code_output true
# One-way, file log service

begin
File.unlink(service_log = "service.log") rescue nil
SomeService.client.transport = SI::Transport::File.new(:file => service_log)
SomeService.client.transport.encoder = SI::Coder::Yaml.new

pr SomeService.client.do_it(1, 2)

ensure
SomeService.client.transport.close

puts "#{service_log.inspect} contents:"
puts File.read(service_log)
end

# !SLIDE :index 550 :capture_code_output true
# Replay file log

begin
SomeService.client.transport = SI::Transport::File.new(:file => service_log)
SomeService.client.transport.encoder = SI::Coder::Yaml.new

SomeService.client.transport.service_file!

ensure
File.unlink(service_log) rescue nil
end

# !SLIDE :index 601 :capture_code_output true
# One-way, named pipe service

begin
File.unlink(service_fifo = "service.fifo") rescue nil
SomeService.client.transport = SI::Transport::File.new(:file => service_fifo)
SomeService.client.transport.encoder = SI::Coder::Yaml.new

SomeService.client.transport.prepare_fifo_server!
child_pid = Process.fork do 
  SomeService.client.transport.run_fifo_server!
end

pr SomeService.client.do_it(1, 2)

ensure
SomeService.client.transport.close
sleep 2
Process.kill 9, child_pid
end

# !SLIDE :index 701 :capture_code_output true
# One-way, named pipe service with signature

begin
File.unlink(service_fifo = "service.fifo") rescue nil
SomeService.client.transport = SI::Transport::File.new(:file => service_fifo)
SomeService.client.transport.encoder = 
  SI::Coder::Multi.new(:encoders =>
                         [ SI::Coder::Marshal.new,
                           SI::Coder::Sign.new(:secret => 'abc123'),
                           SI::Coder::Yaml.new,
                         ])

SomeService.client.transport.prepare_fifo_server!
child_pid = Process.fork do 
  SomeService.client.transport.run_fifo_server!
end

pr SomeService.client.do_it(1, 2)

ensure
SomeService.client.transport.close
sleep 2
Process.kill 9, child_pid
end


# !SLIDE :index 801 :capture_code_output true
# One-way, named pipe service with invalid signature

begin
File.unlink(service_fifo = "service.fifo") rescue nil
SomeService.client.transport = SI::Transport::File.new(:file => service_fifo)
SomeService.client.transport.encoder = 
  SI::Coder::Multi.new(:encoders =>
                         [ SI::Coder::Marshal.new,
                           SI::Coder::Sign.new(:secret => 'abc123'),
                           SI::Coder::Yaml.new,
                         ])

SomeService.client.transport.prepare_fifo_server!
child_pid = Process.fork do 
  SomeService.client.transport.run_fifo_server!
end

SomeService.client.transport.encoder.encoders[1].secret = 'I dont know the secret! :('

pr SomeService.client.do_it(1, 2)

ensure
SomeService.client.transport.close
sleep 2
Process.kill 9, child_pid
end


# !SLIDE :index 901 :capture_code_output true
# Socket service

begin
SomeService.client.transport = SI::Transport::TcpSocket.new(:port => 50901)
SomeService.client.transport.encoder = 
    SI::Coder::Marshal.new

SomeService.client.transport.prepare_socket_server!
child_pid = Process.fork do 
  SomeService.client.transport.run_socket_server!
end

pr SomeService.client.do_it(1, 2)

ensure
SomeService.client.transport.close
sleep 2
Process.kill 9, child_pid
end

# !SLIDE :index 1001 :capture_code_output true
# Socket service with forwarded exception.

begin
SomeService.client.transport = SI::Transport::TcpSocket.new(:port => 51001)
SomeService.client.transport.encoder = 
    SI::Coder::Marshal.new

SomeService.client.transport.prepare_socket_server!
child_pid = Process.fork do 
  SomeService.client.transport.run_socket_server!
end

pr SomeService.client.do_raise("Raise Me!")

rescue Exception => err
  pr [ :exception, err ]
ensure
SomeService.client.transport.close
sleep 2
Process.kill 9, child_pid
end


# !SLIDE END

######################################################################
exit 0

