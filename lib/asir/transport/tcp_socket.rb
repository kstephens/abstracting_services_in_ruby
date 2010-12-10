require 'socket'

module ASIR
  class Transport
    # !SLIDE
    # TCP Socket Transport
    class TcpSocket < Stream
      include PayloadIO
      attr_accessor :port, :address
      
      # !SLIDE
      # Returns a connected TCP socket.
      def stream 
        @stream ||=
          begin
            addr = address || '127.0.0.1'
            _log { "connect #{addr}:#{port}" }
            sock = TCPSocket.open(addr, port)
            sock
          rescue Exception => err
            raise Error, "Cannot connect to #{addr}:#{port}: #{err.inspect}", err.backtrace
          end
      end

      # !SLIDE
      # Sends the encoded Request payload String.
      def _send_request request_payload
        _write request_payload, stream
      end

      # !SLIDE
      # Receives the encoded Request payload String.
      def _receive_request stream
        _read stream
      end

      # !SLIDE
      # Sends the encoded Response payload String.
      def _send_response response_payload, stream
        _write response_payload, stream
      end

      # !SLIDE
      # Receives the encoded Response payload String.
      def _receive_response opaque
        _read stream
      end

      # !SLIDE
      # TCP Socket Server

      def prepare_socket_server!
        _log { "prepare_socket_server! #{port}" }
        @server = TCPServer.open(port)
        @server.setsockopt(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, false)
      end

      def run_socket_server!
        _log :run_socket_server!
        @running = true
        while @running
          stream = @server.accept
          _log { "run_socket_server!: connected" }
          begin
            # Same socket for both in and out stream.
            serve_stream! stream, stream
          ensure
            stream.close
          end
          _log { "run_socket_server!: disconnected" }
        end
      end

    end
    # !SLIDE END
  end # class
end # module


