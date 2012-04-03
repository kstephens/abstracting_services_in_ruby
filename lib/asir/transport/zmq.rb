require 'asir/transport/connection_oriented'
gem 'zmq'
require 'zmq'

module ASIR
  class Transport
    # !SLIDE
    # ZeroMQ Transport
    class Zmq < ConnectionOriented
      attr_accessor :queue

      # !SLIDE
      # 0MQ client.
      def _client_connect!
        sock = zmq_context.socket(one_way ? ZMQ::PUB : ZMQ::REQ)
        sock.connect(uri)
        sock
      end

      # !SLIDE
      # 0MQ server.
      def _server!
        sock = zmq_context.socket(@one_way ? ZMQ::SUB : ZMQ::REP)
        sock.setsockopt(ZMQ::SUBSCRIBE, @queue || "") if @one_way
        sock.bind(uri)
        @server = sock
      end

      def _receive_result message, opaque_result
        return nil if @one_way
        super
      end

      def _send_result message, result, result_payload, stream, message_state
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
        _log { "run_server! #{uri}" } if @verbose >= 1
        with_server_signals! do
          @running = true
          while @running
            begin
              # Inbound only.
              serve_stream_message!(@server, @one_way ? nil : @server)
            rescue Error::Terminate => err
              @running = false
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


