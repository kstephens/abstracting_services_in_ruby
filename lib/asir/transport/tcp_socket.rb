require 'asir/transport/stream'
require 'asir/transport/payload_io'

require 'socket'

module ASIR
  class Transport
    # !SLIDE
    # TCP Socket Transport
    class TcpSocket < Stream
      include PayloadIO
      attr_accessor :port, :address
      
      # !SLIDE
      # Returns a connected TCP socket Channel.
      def stream 
        @stream ||=
          connect_tcp_socket
      end

      # Yields (socket) after _connect_tcp_socket (TCPSocket.open(...)).
      def connect_tcp_socket &blk
        Channel.new(:on_connect => 
          lambda { | channel | 
            socket = _connect_tcp_socket
            blk.call(socket) if blk
            socket
          })
      end

      def _connect_tcp_socket
        addr = address || '127.0.0.1'
        _log { "connect_tcp_socket #{addr}:#{port}" }
        sock = TCPSocket.open(addr, port)
        _log { "connect_tcp_socket: socket=#{sock}" }
        _after_connect! sock
        sock
      rescue ::Exception => err
        raise Error, "Cannot connect to #{addr}:#{port}: #{err.inspect}", err.backtrace
      end

      # Subclasses can override.
      def _after_connect! stream
        self
      end

      # Subclasses can override.
      def _before_close! stream
        self
      end

      # !SLIDE
      # Sends the encoded Request payload String.
      def _send_request request, request_payload
        stream.with_stream! do | stream |
        _write request_payload, stream
        end
      end

      # !SLIDE
      # Receives the encoded Request payload String.
      def _receive_request stream, additional_data
        [ _read(stream), nil ]
      end

      # !SLIDE
      # Sends the encoded Response payload String.
      def _send_response request, response, response_payload, stream, request_state
        _write response_payload, stream
      end

      # !SLIDE
      # Receives the encoded Response payload String.
      def _receive_response opaque
        stream.with_stream! do | stream |
        _read stream
        end
      end

      # !SLIDE
      # TCP Socket Server

      def prepare_socket_server!
        _log { "prepare_socket_server! #{address}:#{port}" }
        @server = TCPServer.open(port)
        @server.setsockopt(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, false)
      rescue ::Exception => err
        _log [ "prepare_socket_server! #{address}:#{port}", :exception, err ]
        raise Error, "Cannot bind to #{address}:#{port}: #{err.inspect}", err.backtrace
      end
      alias :prepare_server! :prepare_socket_server!

      def run_socket_server!
        _log { "connect_tcp_socket #{address}:#{port}" }
        with_server_signals! do
          @running = true
          while @running
            stream = @server.accept
            _log { "run_socket_server!: connected" } if @verbose >= 1
            begin
              # Same socket for both in and out stream.
              serve_stream! stream, stream
            ensure
              stream.close rescue nil
            end
            _log { "run_socket_server!: disconnected" } if @verbose >= 1
          end
        end
        self
      ensure
        if @server
          @server.close rescue nil
        end
        @server = nil
      end
      alias :run_server! :run_socket_server!

    end
    # !SLIDE END
  end # class
end # module


