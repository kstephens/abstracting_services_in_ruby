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
        sock.connect(zmq_uri)
        sock
      rescue ::Exception => exc
        raise exc.class, "#{self.class} #{zmq_uri}: #{exc.message}", exc.backtrace
      end

      # !SLIDE
      # 0MQ server.
      def _server!
        sock = zmq_context.socket(one_way ? ZMQ::SUB : ZMQ::REP)
        sock.setsockopt(ZMQ::SUBSCRIBE, queue) if one_way
        sock.bind("tcp://*:#{port}") # WTF?: why doesn't tcp://localhost:PORT work?
        @server = sock
      rescue ::Exception => exc
        raise exc.class, "#{self.class} #{zmq_uri}: #{exc.message}", exc.backtrace
      end

      def _receive_result message, opaque_result
        return nil if one_way || message.one_way
        super
      end

      def _send_result message, result, result_payload, stream, message_state
        return nil if one_way || message.one_way
        super
      end

      def _write payload, stream
        payload.insert(0, queue_) if one_way
        stream.send payload, 0
        stream
      end

      def _read stream
        stream.recv 0
      end

      # def scheme; SCHEME; end; SCHEME = 'tcp'.freeze
      def queue
        @queue ||=
          (
          case
          when @uri
            x = URI.parse(@uri).path
          else
            x = ""
          end
          # x << "\t" unless x.empty?
          x.freeze
          )
      end
      def queue_
        @queue_ ||=
          (queue.empty? ? queue : queue + " ").freeze
      end


      def run_server!
        _log { "run_server! #{uri}" } if @verbose >= 1
        with_server_signals! do
          @running = true
          while @running
            begin
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

      def zmq_uri
        @zmq_uri ||=
          (
          u = URI.parse(uri)
          u.path = ''
          u.to_s.freeze
          )
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


