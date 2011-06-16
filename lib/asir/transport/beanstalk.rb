require 'asir/transport/tcp_socket'

module ASIR
  class Transport
    # !SLIDE
    # Beanstalk Transport
    class Beanstalk < TcpSocket
      LINE_TERMINATOR = "\r\n".freeze

      attr_accessor :tube, :priority, :delay, :ttr

      def initialize *args
        @port ||= 11300
        @tube ||= 'asir'
        @priority ||= 0
        @delay ||= 0
        @ttr ||= 600
        super
      end

      # !SLIDE
      # Sends the encoded Request payload String.
      def _send_request request, request_payload
        stream.with_stream! do | s |
          begin
            match = 
              _beanstalk(s, 
                         "put #{request[:beanstalk_priority] || @priority} #{request[:beanstalk_delay] || @delay} #{request[:beanstalk_ttr] || @ttr} #{request_payload.size}\r\n",
                         /\AINSERTED (\d+)\r\n\Z/,
                         request_payload)
            job_id = request[:beanstalk_job_id] = match[1].to_i
            _log { "beanstalk_job_id = #{job_id.inspect}" } if @verbose >= 2
          rescue ::Exception => exc
            request[:beanstalk_error] = exc
            close
            raise exc
          end
        end
      end

      RESERVE = "reserve\r\n".freeze

      # !SLIDE
      # Receives the encoded Request payload String.
      def _receive_request channel, additional_data
        channel.with_stream! do | stream |
          begin
            match = 
              _beanstalk(stream,
                         RESERVE,
                         /\ARESERVED (\d+) (\d+)\r\n\Z/)
            additional_data[:beanstalk_job_id] = match[1].to_i
            additional_data[:beanstalk_request_size] = 
              size = match[2].to_i
            request_payload = stream.read(size)
            _read_line_and_expect! stream, /\A\r\n\Z/
            # Pass the original stream used to #_send_response below.
            [ request_payload, stream ]
          rescue ::Exception => exc
            _log { [ :_receive_request, :exception, exc ] }
            additional_data[:beanstalk_error] = exc
            channel.close
          end
        end
      end

      # !SLIDE
      # Sends the encoded Response payload String.
      def _send_response request, response, response_payload, channel, stream
        #
        # There is a possibility here the following could happen:
        #
        #   _receive_request
        #     channel == #<Channel:1>   
        #     channel.stream == #<TCPSocket:1234>
        #   end
        #   ...
        #   ERROR OCCURES:
        #      channel.stream.close
        #      channel.stream = nil
        #   ...
        #   _send_response 
        #     channel == #<Channel:1>
        #     channel.stream == #<TCPSocket:5678> # NEW CONNECTION
        #     stream.write "delete #{job_id}"
        #   ...
        #
        # Therefore: _receiver_request passes the original request stream to us.
        # We insure that the same stream is still the active one and use it.
        channel.with_stream! do | maybe_other_stream |
          _log [ :_send_response, "stream lost" ] if maybe_other_stream != stream
          job_id = request[:beanstalk_job_id] or raise "no beanstalk_job_id"
          _beanstalk(stream,
                     "delete #{job_id}\r\n",
                     /\ADELETED\r\n\Z/)
        end
      end

      # !SLIDE
      # Receives the encoded Response payload String.
      def _receive_response opaque
        nil
      end

      # !SLIDE
      # Sets beanstalk_delay if request.delay was specified.
      def relative_request_delay! request, now = nil
        if delay = super
          request[:beanstalk_delay] = delay.to_i
        end
        delay
      end

      # !SLIDE
      # Beanstalk protocol support

      # Send "something ...\r\n".
      # Expect /\ASOMETHING (\d+)...\r\n".
      def _beanstalk stream, request, expect, payload = nil
        _log { [ :_beanstalk, :request, request ] } if @verbose >= 3
        stream.write request
        if payload
          stream.write payload
          stream.write LINE_TERMINATOR
        end
        stream.flush
        if match = _read_line_and_expect!(stream, expect)
          _log { [ :_beanstalk, :response, match[0] ] } if @verbose >= 3
        end
        match
      end

      def _after_connect! stream
        if @tube
          _beanstalk(stream,
                     "use #{@tube}\r\n",
                     /\AUSING #{@tube}\r\n\Z/)
        end
      end

      # !SLIDE
      # Beanstalk Server

      def prepare_beanstalk_server!
        _log { "prepare_beanstalk_server! #{address}:#{port}" }
        @server = connect_tcp_socket(:try_max => nil,
                                     :try_sleep => 1,
                                     :try_sleep_increment => 0.1,
                                     :try_sleep_max => 10) do | stream |
          if @tube
            _beanstalk(stream, 
                       "watch #{@tube}\r\n",
                       /\AWATCHING (\d+)\r\n\Z/)
          end
        end
        self
      end
      alias :prepare_server! :prepare_beanstalk_server!

      def run_beanstalk_server!
        _log :run_beanstalk_server!
        with_server_signals! do
          @running = true
          while @running
            prepare_beanstalk_server! unless @server
            # Same socket for both in and out stream.
            serve_stream! @server, @server
          end
        end
        self
      ensure
        close_server!
      end
      alias :run_server! :run_beanstalk_server!
 
      def serve_stream! in_stream, out_stream
        while @running
          begin
            serve_stream_request! in_stream, out_stream
          rescue ::Exception => exc
            _log [ :serve_stream_error, exc ]
            @running = false
          end
        end
        self
      ensure
        close_server!
      end

      def close_server!
        if @server
          @server.close
        end
      ensure
        @server = nil
      end

      def start_beanstalkd!
        _log { "run_beanstalkd! #{address}:#{port}" }
        raise "already running #{@beanstalkd_pid}" if @beanstalkd_pid
        addr = address ? "-l #{address} " : ""
        cmd = "beanstalkd #{addr}-p #{port}"
        @beanstalkd_pid = Process.fork do 
          $stderr.puts "Start beanstalkd: #{cmd} ..."
          exec(cmd)
          raise "exec #{cmd.inspect} failed"
        end
        $stderr.puts "Start beanstalkd: #{cmd} pid=#{@beanstalkd_pid.inspect}"
        self
      end

      def stop_beanstalkd!
        _log { "stop_beanstalkd! #{address}:#{port} pid=#{@beanstalkd_pid.inspect}" }
        Process.kill 'TERM', @beanstalkd_pid
        Process.waitpid @beanstalkd_pid
        self
      ensure
        @beanstalkd_pid = nil
      end

    end
    # !SLIDE END
  end # class
end # module

