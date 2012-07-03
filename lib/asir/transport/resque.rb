require 'asir/transport/connection_oriented'
gem 'resque'
require 'resque'
require 'asir/poll_throttle'

module ASIR
  class Transport
    # !SLIDE
    # Resque Transport
    class Resque < ConnectionOriented
      include PollThrottle

      attr_accessor :queues, :queue, :namespace

      # !SLIDE
      # Resque client.
      def _client_connect!
        sock = zmq_context.socket(one_way ? ZMQ::PUB : ZMQ::REQ)
        sock.connect(zmq_uri)
        sock
      rescue ::Exception => exc
        raise exc.class, "#{self.class} #{zmq_uri}: #{exc.message}", exc.backtrace
      end

      # !SLIDE
      # Resque server (worker).
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

      # Based on Resque.enqueue
      def _write payload, stream
        klass = self.class
        ::Resque::Job.create(queue, klass, payload)
        Plugin.after_enqueue_hooks(klass).each do | hook |
          klass.send(hook, payload)
        end
      end

      def _read stream
        
      end

      # def scheme; SCHEME; end; SCHEME = 'tcp'.freeze
      def queues
        @queues ||=
          (
          case
          when @uri
            x = URI.parse(@uri).path
          else
            x = ""
          end
          x = x.split(/(\s+|\s*,\s*)/)
          x.freeze
          )
      end

      # Defaults to [ 'asir' ].
      def queues_
        @queues_ ||=
          (queues.empty? ? [ 'asir' ] : queues.freeze
      end

      # Defaults to 'asir'.
      def queue
        @queue ||= queues_.first || 'asir'.freeze
      end

      def namespace_
        @namespace_ ||= namespace || 'asir'.freeze
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

      def resque_uri
        @resque_uri ||=
          (
          unless scheme == 'redis'
            raise ArgumentError, "Invalid resque URI: #{uri.inspect}"
          end
          URI.parse(uri)
          )
      end

      def resque_connect!
        ::Resque.redis =
          ::Redis::Namespace.new(namespace_,
                             :redis => ::Redis.new(
                                               :host => address || '127.0.0.1',
                                               :port => port || 6379
                                               )
                             )
        ::Resque.redis.
      end

      def resque_worker
        @resque_worker ||= ::Resque::Worker.new(queues_)
      end
    end
    # !SLIDE END
  end # class
end # module


