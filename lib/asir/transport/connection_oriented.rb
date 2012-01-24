require 'asir/transport/stream'
require 'asir/transport/payload_io'

module ASIR
  class Transport
    # !SLIDE
    # Connection-Oriented Transport
    class ConnectionOriented < Stream
      include PayloadIO

      attr_accessor :uri, :port, :address

      def uri
        @uri ||= "tcp://#{address}:#{port}"
      end

      def address
        @address ||= '127.0.0.1'.freeze
      end

      # !SLIDE
      # Returns a connected Channel.
      def stream
        @stream ||=
          connect!
      end

      # Yields Channel after _connect!.
      def connect!(opts = nil, &blk)
        base_opts = {
          :on_connect => lambda { | channel |
            connection = _connect!
            blk.call(connection) if blk
            connection
          }
        }
        base_opts.update(opts) if opts
        Channel.new(base_opts)
      end

      # Returns raw client stream.
      def _connect!
        _log { "_connect! #{uri}" }
        sock = _client_connect!
        _log { "_connect! socket=#{sock}" }
        _after_connect! sock
        sock
      rescue ::Exception => err
        raise Error, "Cannot connect to #{self.class} #{uri}: #{err.inspect}", err.backtrace
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
        stream.with_stream! do | io |
          _write request_payload, io
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
      def _receive_response request, opaque_response
        stream.with_stream! do | io |
          _read io
        end
      end

      # !SLIDE
      # Server

      def prepare_server!
        _log { "prepare_server! #{uri}" }
        _server!
      rescue ::Exception => err
        _log [ "prepare_server! #{uri}", :exception, err ]
        raise Error, "Cannot prepare server on #{self.class} #{uri}: #{err.inspect}", err.backtrace
      end

      def run_server!
        _log { "run_server! #{uri}" }
        with_server_signals! do
          @running = true
          while @running
            stream = _server_accept_connection! @server
            _log { "run_server!: connected" } if @verbose >= 1
            begin
              # Same socket for both in and out stream.
              serve_stream! stream, stream
            ensure
              _server_close_connection!(stream)
            end
            _log { "run_server!: disconnected" } if @verbose >= 1
          end
        end
        self
      ensure
        _server_close!
      end

      def _server!
        raise Error::SubclassResponsibility, "_server!"
      end

      def _server_close!
        if @server
          @server.close rescue nil
        end
        @server = nil
        self
      end

      # Accept a client connection.
      def _server_accept_connection! server
        raise Error::SubclassResponsibility, "_server_accept_connection!"
      end

      # Close a client connection.
      def _server_close_connection! stream
        raise Error::SubclassResponsibility, "_server_close_connection!"
      end
    end
    # !SLIDE END
  end # class
end # module

