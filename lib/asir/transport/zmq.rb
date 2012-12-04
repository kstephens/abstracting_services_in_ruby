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

      def _write payload, stream, context
        if one_way
          q = context && (context[:queue] || context[:zmq_queue])
          payload.insert(0, q || queue_)
        end
        stream.send payload, 0
        stream
      end

      def _read stream, context
        stream.recv 0
      end

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

      # server represents a receiving ZMQ endpoint.
      def _server_accept_connection! server
        [ server, @one_way ? nil : server ]
      end

      # ZMQ is message-oriented, process only one message per "connection".
      alias :_server_serve_stream :serve_message!

      def stream_eof? stream
        false
      end

      # Nothing to be closed for ZMQ.
      def _server_close_connection! in_stream, out_stream
        # NOTHING
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


