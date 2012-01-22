require 'asir/transport/connection_oriented'
require 'socket'

module ASIR
  class Transport
    # !SLIDE
    # TCP Socket Transport
    class TcpSocket < ConnectionOriented
      attr_accessor :port, :address
      def uri
        "tcp://#{addr}:#{port}/"
      end

      def addr
        address || '127.0.0.1'
      end

      def _connect!
        _log { "_connect! #{uri}" }
        sock = TCPSocket.open(addr, port)
        _log { "_connect!: socket=#{sock}" }
        _after_connect! sock
        sock
      rescue ::Exception => err
        raise Error, "Cannot connect to #{self.class} #{uri}: #{err.inspect}", err.backtrace
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


