module ASIR
  class Transport
    # !SLIDE
    # Stream Transport
    #
    # Base class handles Messages on a stream.
    # Stream Transports require a Coder that encodes to and from String payloads.
    class Stream < self

      # !SLIDE
      # Serve all Messages from a stream.
      def serve_stream! in_stream, out_stream
        with_server_signals! do
          @running = true
          _serve_stream! in_stream, out_stream
        end
      end

      def _serve_stream! in_stream, out_stream
        while @running && ! stream_eof?(in_stream)
          begin
            serve_stream_message! in_stream, out_stream
          rescue *Error::Unrecoverable.modules
            raise
          rescue Error::Terminate => err
            @running = false
            _log [ :serve_stream_terminate, err ]
          rescue ::Exception => err
            _log [ :serve_stream_error, err, err.backtrace ]
            raise err
          end
        end
      end

      # Subclasses can override this method.
      def stream_eof? stream
        stream.eof?
      end

      # !SLIDE
      # Serve a Message from a stream.
      def serve_stream_message! in_stream, out_stream
        serve_message! in_stream, out_stream
      end
    end
    # !SLIDE END
  end
end
