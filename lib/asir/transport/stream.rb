module ASIR
  class Transport
    # !SLIDE
    # Stream Transport
    #
    # Base class handles Requests on stream.
    # Stream Transports require a Coder that encodes to and from String payloads.
    class Stream < self

      # !SLIDE
      # Serve all Requests from a stream.
      def serve_stream! in_stream, out_stream
        until in_stream.eof?
          begin
            serve_stream_request! in_stream, out_stream
          rescue Exception => err
            _log [ :serve_stream_error, err ]
          end
        end
      end

      # !SLIDE
      # Serve a Request from a stream.
      def serve_stream_request! in_stream, out_stream
        serve_request! in_stream, out_stream
      end
    end
    # !SLIDE END
  end
end
