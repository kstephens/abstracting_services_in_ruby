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

      def initialize *args
        @port_default = 6379
        super
        self.one_way = true
      end

      # !SLIDE
      # Resque client.
      def _client_connect!
        resque_connect!
      rescue ::Exception => exc
        raise exc.class, "#{self.class} #{uri}: #{exc.message}", exc.backtrace
      end

      # !SLIDE
      # Resque server (worker).
      def _server!
        resque_connect!
        resque_worker
      rescue ::Exception => exc
        raise exc.class, "#{self.class} #{uri}: #{exc.message}", exc.backtrace
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
        Resque.enqueue_to(queue, self.class, :process_job, payload)
      end

      def _read stream # stream *is* the payload
        stream
      end

      def queues
        @queues ||=
          (
          case
          when @uri
            x = _uri.path
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
          (queues.empty? ? [ DEFAULT_QUEUE ] : queues.freeze
      end

      # Defaults to 'asir'.
      def queue
        @queue ||= queues_.first || DEFAULT_QUEUE
      end

      # Defaults to 'asir'.
      def namespace_
        @namespace_ ||= namespace || DEFAULT_QUEUE
      end

      DEFAULT_QUEUE = 'asir'.freeze

      def run_server!
        _log { "run_server! #{uri}" } if @verbose >= 1
        with_server_signals! do
          @running = true
          while @running
            begin
              serve_stream_message!(nil, nil)
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

      def serve_stream_message! in_stream, out_stream # ignored
        save = Thread.current[:asir_transport_resque_payload]
        Thread.current[:asir_transport_resque_payload] = nil
        poll_throttle \
          :inc_sleep => 1,
          :mul_sleep => 1.5,
          :rand_sleep => 0.1 \
        do
          resque_worker.process
        end
        self
      ensure
        Thread.current[:asir_transport_resque_payload] = save
      end

      def self.process_job payload
        Thread.current[:asir_transport_resque_payload] = payload
      end

      def receive_message in_stream # ignored
        payload = Thread.current[:asir_transport_resque_payload]
        [ payload, nil ]
      end

      ####################################

      def resque_uri
        @resque_uri ||=
          (
          unless scheme == 'redis'
            raise ArgumentError, "Invalid resque URI: #{uri.inspect}"
          end
          _uri
          )
      end

      def resque_connect!
        @redis = ::Redis.new(
                         :host => address || '127.0.0.1',
                         :port => port || 6379
                         )
        if namespace_
          ::Resque.redis =
            @redis =
            ::Redis::Namespace.new(namespace_, :redis => @redis)
          ::Resque.redis.namespace = namespace_
        else
          ::Resque.redis = @redis
        end
        @redis
      end

      def resque_disconnect!
        ::Resque.redis = nil
      end

      def resque_worker
        @resque_worker ||= ::Resque::Worker.new(queues_)
      end

    end
    # !SLIDE END
  end # class
end # module


