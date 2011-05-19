require 'socket'

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

      def _read stream, size
        _log { "_read #{stream} #{size} ..." }
        result = stream.read size
        _log { "_read #{stream} #{size} => #{result.inspect}" }
        result
      end

      def _write payload, stream
        _log { "_write #{stream} #{payload.size} #{payload.inspect}" }
        stream.write payload
      end

      def _after_connect! stream
        if @tube
          _write "use #{@tube}\r\n", stream
          _read_line_and_expect! stream, /\AUSING #{@tube}\r\n\Z/
        end
      end

      # !SLIDE
      # Sends the encoded Request payload String.
      def _send_request request, request_payload
        s = stream
        beanstalk_request = "put #{request[:beanstalk_priority] || @priority} #{@delay} #{@ttr} #{request_payload.size}\r\n"
        _write beanstalk_request, s
        _write request_payload, s
        _write LINE_TERMINATOR, s
        stream.flush
        match = _read_line_and_expect! s, /\AINSERTED (\d+)\r\n\Z/
        job_id = request[:beanstalk_job_id] = match[1].to_i
        _log { "beanstalk_job_id = #{job_id.inspect}" }
      rescue Exception => err
        request[:beanstalk_error] = err
        close
        raise err
      end

      RESERVE = "reserve\r\n".freeze

      # !SLIDE
      # Receives the encoded Request payload String.
      def _receive_request stream, additional_data
        _write RESERVE, stream
        stream.flush
        match = _read_line_and_expect! stream, /\ARESERVED (\d+) (\d+)\r\n\Z/
        additional_data[:beanstalk_job_id] = match[1].to_i
        additional_data[:beanstalk_request_size] = 
        size = match[2].to_i
        request_payload = _read stream, size
        _read_line_and_expect! stream, /\A\r\n\Z/
        request_payload
      rescue Exception => err
        additional_data[:beanstalk_error] = err
        close
      end

      # !SLIDE
      # Sends the encoded Response payload String.
      def _send_response response, response_payload, stream
        job_id = response.request[:beanstalk_job_id] or raise "no beanstalkd_job_id"
        beanstalk_request = "delete #{job_id}\r\n"
        _write beanstalk_request, stream
        stream.flush
        _read_line_and_expect! stream, /\ADELETED\r\n\Z/
      end

      # !SLIDE
      # Receives the encoded Response payload String.
      def _receive_response opaque
        nil
      end

      # !SLIDE
      # TCP Socket Server

      def prepare_beanstalk_server!
        _log { "prepare_beanstalk_server! #{address}:#{port}" }
        stream = @server = connect_tcp_socket
        if @tube
          _write "watch #{@tube}\r\n", stream
          stream.flush
          _read_line_and_expect! stream, /\AWATCHING (\d+)\r\n\Z/
        end
        self
      end

      def run_beanstalk_server!
        _log :run_beanstalk_server!
        @running = true
        while @running
          prepare_beanstalk_server! unless @server
          stream = @server

          # Same socket for both in and out stream.
          serve_stream! stream, stream
          close_server!
        end
        self
      ensure
        close_server!
      end
 
      def serve_stream! in_stream, out_stream
        while @running
          begin
            serve_stream_request! in_stream, out_stream
          rescue Exception => err
            _log [ :serve_stream_error, err ]
            close_server!
            break
          end
        end
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
        cmd = "beanstalkd -l #{address} -p #{port}"
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


