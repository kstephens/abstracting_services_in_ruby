require 'asir/transport/connection_oriented'
require 'socket'

module ASIR
  class Transport
    # !SLIDE
    # TCP Socket Transport
    class TcpSocket < ConnectionOriented
      # !SLIDE
      # TCP Socket Client
      def _client_connect!
        sock = ::TCPSocket.open(host, port)
      end

      # !SLIDE
      # TCP Socket Server
      def _server!
        @server = ::TCPServer.open(port)
        @server.setsockopt(::Socket::SOL_SOCKET, ::Socket::SO_KEEPALIVE, false)
      end

      def _server_accept_connection! server
        socket = server.accept
        [ socket, socket ] # Use same socket for in_stream and out_stream
      end

      def _server_close_connection! in_stream, out_stream
        in_stream.close rescue nil
      end
    end
    # !SLIDE END
  end # class
end # module


