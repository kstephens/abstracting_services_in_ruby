require 'asir/transport/connection_oriented'
require 'socket'

module ASIR
  class Transport
    # !SLIDE
    # TCP Socket Transport
    class TcpSocket < ConnectionOriented
      # !SLIDE
      # TCP Socket Client.
      def _client_connect!
        sock = TCPSocket.open(addr, port)
      end

      # !SLIDE
      # TCP Socket Server
      def _server!
        @server = TCPServer.open(port)
        @server.setsockopt(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, false)
      end

      def _server_accept_connection! server
        server.accept
      end

      def _server_close_connection! stream
        stream.close rescue nil
      end
    end
    # !SLIDE END
  end # class
end # module


