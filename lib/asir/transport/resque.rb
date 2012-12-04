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
        # $stderr.puts "  #{$$} #{self} _server!"
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
          queue = message[:resque_queue] || message[:queue] || self.queue
          $stderr.puts "  #{$$} #{self} _send_message #{message_payload.inspect} to queue=#{queue.inspect} as #{self.class} :process_job" if @verbose >= 2
          # Invokes Transport::Resque.perform(metadata, payload)
          metadata = message[:resque_metadata] || message.description
          ::Resque.enqueue_to(queue, self.class, metadata, message_payload)
        end
      end

      def queues
        @queues ||=
          (
          x = nil
          x = path if @uri
          x ||= ""
          root, x = x.split('/')
          x ||= ""
          x = x.split(/(\s+|\s*,\s*)/)
          x.each(&:freeze)
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
        save = ::Thread.current[:asir_transport_resque_instance]
        ::Thread.current[:asir_transport_resque_instance] = self
        poll_throttle throttle do
          $stderr.puts "  #{$$} #{self} serve_stream_message!: resque_worker = #{resque_worker} on queues #{resque_worker.queues.inspect}" if @verbose >= 3
          if job = resque_worker.reserve
            $stderr.puts "  #{$$} #{self} serve_stream_message! job=#{job.class}:#{job.inspect}" if @verbose >= 2
            resque_worker.process(job)
          end
          job
        end
        self
      ensure
        ::Thread.current[:asir_transport_resque_instance] = save
      end

      # Class method entry point from Resque::Job.perform.
      def self.perform metadata, payload = nil
        payload ||= metadata # old calling signature (just payload).
        # $stderr.puts "  #{self} process_job payload=#{payload.inspect}"
        t = ::Thread.current[:asir_transport_resque_instance]
        # Pass payload as in_stream; _receive_message will return it.
        t.serve_message! payload, nil
      end

      def _receive_message payload, additional_data # is actual payload
        # $stderr.puts "  #{$$} #{self} _receive_message payload=#{payload.inspect}"
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
        @redis_config = {
          :host => host,
          :port => port,
          :thread_safe => true,
        }
        @redis =
          ::Redis.new(@redis_config)
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
        @resque_worker ||= ::Resque::Worker.new(*queues_)
      end

      def server_on_start!
        # prune_dead_workers expects processes to have "resque " in the name.
        @save_progname ||= $0.dup
        $0 = "resque #{$0}"
        if worker = resque_worker
          worker.prune_dead_workers
          worker.register_worker
        end
        self
      end

      def server_on_stop!
        $0 = @save_progname if @save_progname
        if worker = @resque_worker
          worker.unregister_worker
        end
        self
      rescue Redis::CannotConnectError
        # This error is not actionable since server
        # is stopping.
        nil
      end

      #########################################

      @@redis_server_version = nil
      def redis_server_version
        @@redis_server_version ||=
          begin
            case v = `redis-server --version`
            when /v=([.0-9]+)/ # 3.x
              v = $1
            when / version ([.0-9]+)/ # 2.x
              v = $1
            else
              v = 'UNKNOWN'
            end
            v
          end
      end

      def _start_conduit!
        @redis_dir ||= "/tmp"
        @redis_conf ||= "#{@redis_dir}/asir-redis-#{port}.conf"
        @redis_log ||= "#{@redis_dir}/asir-redis-#{port}.log"
        @redis_cmd = [ 'redis-server' ]
        case redis_server_version
        when /^2\.4/
          ::File.open(@redis_conf, "w+") do | out |
            out.puts "daemonize no"
            out.puts "port #{port}"
            out.puts "loglevel warning"
            out.puts "logfile #{@redis_log}"
          end
          @redis_cmd << @redis_conf
        else
          @redis_cmd <<
            '--port'     << port <<
            '--loglevel' << 'warning' <<
            '--logfile'  << @redis_log
        end
        @redis_cmd.map! { | x | x.to_s }
        # $stderr.puts "  redis_cmd = #{@redis_cmd * ' '}" if @verbose >= 1
        exec *@redis_cmd
      end
    end
    # !SLIDE END
  end # class
end # module


