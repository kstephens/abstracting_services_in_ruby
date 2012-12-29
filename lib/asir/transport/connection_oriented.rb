require 'asir/transport/stream'
require 'asir/transport/payload_io'
require 'asir/uri_config'

module ASIR
  class Transport
    # !SLIDE
    # Connection-Oriented Transport
    class ConnectionOriented < Stream
      include PayloadIO, UriConfig

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
        stream = _client_connect!
        _log { "_connect! stream=#{stream}" } if @verbose >= 1
        _after_connect! stream
        stream
      rescue ::Exception => err
        raise err.class, "Cannot connect to #{self.class} #{uri}: #{err.inspect}", err.backtrace
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
      def _send_message state
        stream.with_stream! do | io |
          state.in_stream = io
          _write(state.message_payload, io, state)
        end
      end

      # !SLIDE
      # Receives the encoded Message payload String.
      def _receive_message state
        state.message_payload = _read(state.in_stream, state)
      end

      # !SLIDE
      # Sends the encoded Result payload String.
      def _send_result state
        unless @one_way || state.message.one_way
          # $stderr.write "\n  _send_result #{state.result_payload.inspect}\n\n"
          _write(state.result_payload, state.out_stream, state)
          true
        end
      end

      # !SLIDE
      # Receives the encoded Result payload String.
      def _receive_result state
        unless @one_way || state.message.one_way
          state.result_payload = _read(state.in_stream, state)
          true
        end
      end

      # !SLIDE
      # Server

      def prepare_server!
        _log { "prepare_server! #{uri}" } if @verbose >= 1
        _server!
      rescue ::Exception => err
        _log [ "prepare_server! #{uri}", :exception, err ]
        raise err.class, "Cannot prepare server on #{self.class} #{uri}: #{err.inspect}", err.backtrace
      end

      def run_server!
        _log { "run_server! #{uri}" } if @verbose >= 1
        with_server_signals! do
          @running = true
          server_on_start!
          while @running
            serve_connection!
          end
        end
        self
      ensure
        server_on_stop!
        _server_close!
      end

      def server_on_start!
      end

      def server_on_stop!
      end

      def serve_connection!
        _log { "serve_connection!: accepting connection" } if @verbose >= 2
        in_stream, out_stream = _server_accept_connection! @server
        _log { "serve_connection!: connected #{in_stream} #{out_stream}" } if @verbose >= 1
        _server_serve_stream! in_stream, out_stream
      rescue Error::Terminate => err
        @running = false
        _log [ :serve_connection_terminate, err ]
      ensure
        _server_close_connection!(in_stream, out_stream)
        _log { "serve_connection!: disconnected" } if @verbose >= 1
      end
      alias :_server_serve_stream! :_serve_stream!

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
      # Returns [ in_stream, out_stream ].
      def _server_accept_connection! server
        raise Error::SubclassResponsibility, "_server_accept_connection!"
      end

      # Close a client connection.
      def _server_close_connection! in_stream, out_stream
        raise Error::SubclassResponsibility, "_server_close_connection!"
      end
    end
    # !SLIDE END
  end # class
end # module

