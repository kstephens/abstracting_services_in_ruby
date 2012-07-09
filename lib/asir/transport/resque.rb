require 'asir/transport/connection_oriented'
require 'resque'
require 'asir/poll_throttle'

module ASIR
  class Transport
    # !SLIDE
    # Resque Transport
    class Resque < ConnectionOriented
      include PollThrottle

      attr_accessor :queues, :queue, :namespace, :throttle

      def initialize *args
        @port_default = 6379
        @scheme_default = 'redis'.freeze
        super
        self.one_way = true
        # Reraise exception, let Resque::Worker handle it.
        @on_exeception ||= lambda do | trans, exc, type, message |
          raise exc, exc.backtrace
        end
      end

      # !SLIDE
      # Resque client.
      def _client_connect!
        # $stderr.puts "  #{$$} #{self} _client_connect!"
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

      def _send_message message, message_payload
        stream.with_stream! do | io |  # Force connect
          $stderr.puts "  #{self} _send_message #{message_payload.inspect} to queue=#{queue.inspect} as #{self.class} :process_job"
          ::Resque.enqueue_to(queue, self.class, message_payload)
        end
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
          queues.empty? ? [ DEFAULT_QUEUE ] : queues.freeze
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

      def _server_accept_connection! server
        [ server, server ]
      end

      # Resque is message-oriented, process only one message per "connection".
      def stream_eof? stream
        false
      end

      # Nothing to be closed for Resque.
      def _server_close_connection! in_stream, out_stream
        # NOTHING
      end

      def serve_stream_message! in_stream, out_stream # ignored
        save = Thread.current[:asir_transport_resque_instance]
        Thread.current[:asir_transport_resque_instance] = self
        poll_throttle throttle do
          # $stderr.puts "  #{self} serve_stream_message!"
          # $stderr.puts "  #{self} resque_worker = #{resque_worker} on queues #{resque_worker.queues}"
          job = resque_worker.process
          # $stderr.puts "  #{self} serve_stream_message! job=#{job.class}:#{job.inspect}"
        end
        self
      ensure
        Thread.current[:asir_transport_resque_instance] = save
      end

      # Class method entry point from Resque::Job.perform.
      def self.perform payload
        # $stderr.puts "  #{self} process_job payload=#{payload.inspect}"
        t = Thread.current[:asir_transport_resque_instance]
        # Pass payload as in_stream; _receive_message will return it.
        t.serve_message! payload, nil
      end

      def _receive_message payload, additional_data # is actual payload
        # $stderr.puts "  #{self} _receive_message payload=#{payload.inspect}"
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
        @redis =
          ::Redis.new({
                        :host => address || '127.0.0.1',
                        :port => port,
                        :thread_safe => true,
                      })
        if namespace_
          ::Resque.redis =
            @redis =
            ::Redis::Namespace.new(namespace_, :redis => @redis)
          ::Resque.redis.namespace = namespace_
        else
          ::Resque.redis = @redis
        end
        # $stderr.puts "  *** #{$$} #{self} resque_connect! #{@redis.inspect}"
        @redis
      end

      def resque_disconnect!
        ::Resque.redis = nil
      end

      def resque_worker
        @resque_worker ||= ::Resque::Worker.new(queues_)
      end

      #########################################

      def start_redis!
        @redis_conf ||= "redis_#{port}.conf"
        @redis_log ||= "redis_#{port}.log"
        ::File.open(@redis_conf, "w+") do | out |
          out.puts "daemonize no"
          out.puts "port #{port}"
          out.puts "loglevel warning"
          out.puts "logfile #{@redis_log}"
        end
        @redis_pid = ::Process.fork do
          exec "redis-server", @redis_conf
          raise "Could not exec"
        end
        $stderr.puts "*** #{$$} started redis-server pid=#{@redis_pid} port=#{port}"
        self
      end

      def stop_redis!
        if @redis_pid
          ::Process.kill 'TERM', @redis_pid
          ::Process.waitpid @redis_pid
          # File.unlink @redis_conf
        end
        self
      ensure
        @redis_pid = nil
      end

    end
    # !SLIDE END
  end # class
end # module


