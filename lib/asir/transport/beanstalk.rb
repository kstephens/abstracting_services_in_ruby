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
      # Sends the encoded Message payload String.
      def _send_message message, message_payload
        stream.with_stream! do | s |
          begin
            match = 
              _beanstalk(s, 
                         "put #{message[:beanstalk_priority] || @priority} #{message[:beanstalk_delay] || @delay} #{message[:beanstalk_ttr] || @ttr} #{message_payload.size}\r\n",
                         /\AINSERTED (\d+)\r\n\Z/,
                         message_payload)
            job_id = message[:beanstalk_job_id] = match[1].to_i
            _log { "beanstalk_job_id = #{job_id.inspect}" } if @verbose >= 2
          rescue ::Exception => exc
            message[:beanstalk_error] = exc
            close
            raise exc
          end
        end
      end

      RESERVE = "reserve\r\n".freeze

      # !SLIDE
      # Receives the encoded Message payload String.
      def _receive_message channel, additional_data
        channel.with_stream! do | stream |
          begin
            match = 
              _beanstalk(stream,
                         RESERVE,
                         /\ARESERVED (\d+) (\d+)\r\n\Z/)
            additional_data[:beanstalk_job_id] = match[1].to_i
            additional_data[:beanstalk_message_size] = 
              size = match[2].to_i
            message_payload = stream.read(size)
            _read_line_and_expect! stream, /\A\r\n\Z/
            # Pass the original stream used to #_send_result below.
            [ message_payload, stream ]
          rescue ::Exception => exc
            _log { [ :_receive_message, :exception, exc ] }
            additional_data[:beanstalk_error] = exc
            channel.close
            raise exc
          end
        end
      end

      # !SLIDE
      # Sends the encoded Result payload String.
      def _send_result message, result, result_payload, channel, stream
        #
        # There is a possibility here the following could happen:
        #
        #   _receive_message
        #     channel == #<Channel:1>   
        #     channel.stream == #<TCPSocket:1234>
        #   end
        #   ...
        #   ERROR OCCURES:
        #      channel.stream.close
        #      channel.stream = nil
        #   ...
        #   _send_result 
        #     channel == #<Channel:1>
        #     channel.stream == #<TCPSocket:5678> # NEW CONNECTION
        #     stream.write "delete #{job_id}"
        #   ...
        #
        # Therefore: _receiver_message passes the original message stream to us.
        # We insure that the same stream is still the active one and use it.
        channel.with_stream! do | maybe_other_stream |
          _log [ :_send_result, "stream lost" ] if maybe_other_stream != stream
          job_id = message[:beanstalk_job_id] or raise "no beanstalk_job_id"
          _beanstalk(stream,
                     "delete #{job_id}\r\n",
                     /\ADELETED\r\n\Z/)
        end
      end

      # !SLIDE
      # Receives the encoded Result payload String.
      def _receive_result message, opaque_result
        nil
      end

      # !SLIDE
      # Sets beanstalk_delay if message.delay was specified.
      def relative_message_delay! message, now = nil
        if delay = super
          message[:beanstalk_delay] = delay.to_i
        end
        delay
      end

      # !SLIDE
      # Beanstalk protocol support

      # Send "something ...\r\n".
      # Expect /\ASOMETHING (\d+)...\r\n".
      def _beanstalk stream, message, expect, payload = nil
        _log { [ :_beanstalk, :message, message ] } if @verbose >= 3
        stream.write message
        if payload
          stream.write payload
          stream.write LINE_TERMINATOR
        end
        stream.flush
        if match = _read_line_and_expect!(stream, expect)
          _log { [ :_beanstalk, :result, match[0] ] } if @verbose >= 3
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
      def _server!
        _log { "_server! #{uri}" } if @verbose >= 1
        @server = connect!(:try_max => nil,
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

      def _server_accept_connection! server
        prepare_server! unless @server
        [ @server, @server ]
      end

      def _server_close_connection! in_stream, out_stream
        # NOTHING
      end

      def stream_eof? stream
        # Note: stream.eof? on a beanstalkd connection,
        # will cause blocking read *forever* because
        # beanstalk connections are long lived.
        false
      end

      def _start_conduit!
        addr = address ? "-l #{address} " : ""
        cmd = "beanstalkd #{addr}-p #{port}"
        exec(cmd)
      end
    end
    # !SLIDE END
  end # class
end # module

