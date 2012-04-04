require 'asir/transport/stream'
require 'asir/transport/payload_io'
require 'uri'

module ASIR
  class Transport
    # !SLIDE
    # Connection-Oriented Transport
    class ConnectionOriented < Stream
      include PayloadIO

      attr_accessor :uri, :scheme, :port, :address
      alias :protocol :scheme
      alias :protocol= :scheme=

      def uri
        @uri ||= "#{scheme}://#{address}:#{port}"
      end

      def scheme
        @scheme ||=
          case
          when @uri
            URI.parse(@uri).scheme
          else
            'tcp'.freeze
          end
      end

      def address
        @address ||=
          case
          when @uri
            URI.parse(@uri).host
          else
            '127.0.0.1'.freeze
          end
      end

      def port
        @port ||=
          case
          when @uri
            URI.parse(@uri).port
          else
            raise Error, "#{self.class}: port not set."
          end
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
        _log { "_connect! #{uri}" } if @verbose >= 1
        sock = _client_connect!
        _log { "_connect! socket=#{sock}" } if @verbose >= 1
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
      # Sends the encoded Message payload String.
      def _send_message message, message_payload
        stream.with_stream! do | io |
          _write message_payload, io
        end
      end

      # !SLIDE
      # Receives the encoded Message payload String.
      def _receive_message stream, additional_data
        [ _read(stream), nil ]
      end

      # !SLIDE
      # Sends the encoded Result payload String.
      def _send_result message, result, result_payload, stream, message_state
        unless @one_way || message.one_way
          _write result_payload, stream
        end
      end

      # !SLIDE
      # Receives the encoded Result payload String.
      def _receive_result message, opaque_result
        unless @one_way || message.one_way
          stream.with_stream! do | io |
            _read io
          end
        end
      end

      # !SLIDE
      # Server

      def prepare_server!
        _log { "prepare_server! #{uri}" } if @verbose >= 1
        _server!
      rescue ::Exception => err
        _log [ "prepare_server! #{uri}", :exception, err ]
        raise Error, "Cannot prepare server on #{self.class} #{uri}: #{err.inspect}", err.backtrace
      end

      def run_server!
        _log { "run_server! #{uri}" } if @verbose >= 1
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

