require 'asir/transport/connection_oriented'
gem 'zmq'
require 'zmq'

module ASIR
  class Transport
    # !SLIDE
    # ZeroMQ Transport
    class Zmq < ConnectionOriented
      attr_accessor :uri, :port, :address, :queue

      def uri
        @uri || "tcp://#{addr}:#{port}"
      end

      def addr
        address || '127.0.0.1'
      end

      # !SLIDE
      # One-way 0MQ server.
      def _connect!
        _log { "_connect! #{uri}" }
        # sock = zmq_context.socket(ZMQ::UPSTREAM)
        sock = zmq_context.socket(ZMQ::PUB)
        sock.connect(uri)
        _log { "_connect!: connection=#{sock}" }
        _after_connect! sock
        sock
      rescue ::Exception => err
        raise Error, "Cannot connect to #{self.class} #{uri}: #{err.inspect}", err.backtrace
      end

      # !SLIDE
      # One-way 0MQ server.
      def _server!
        # @server = zmq_context.socket(ZMQ::DOWNSTREAM)
        sock = zmq_context.socket(ZMQ::SUB)
        sock.setsockopt(ZMQ::SUBSCRIBE, @queue || "");
        sock.bind(uri)
        @server = sock
      end

      def _receive_response opaque_response
        return nil if @one_way
        super
      end

      def _send_response request, response, response_payload, stream, request_state
        return nil if @one_way
        super
      end

      def _write payload, stream
        stream.send payload, 0
        stream
      end

      def _read stream
        stream.recv 0
      end

      def run_server!
        _log { "run_server! #{uri}" }
        with_server_signals! do
          @running = true
          while @running
            begin
              # Inbound only.
              serve_stream_request! @server, nil
            rescue Error::Terminate => err
              _log [ :run_server_terminate, err ]
            end
          end
        end
        self
      ensure
        _server_close!
      end

      def zmq_context
        @@zmq_context ||=
          ZMQ::Context.new(1)
      end
      @@zmq_context ||= nil
    end
    # !SLIDE END
  end # class
end # module


