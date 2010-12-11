module ASIR
  class Transport
    # !SLIDE
    # File Transport
    #
    # Send Request one-way to a file.
    # Can be used as a log or named pipe service.
    class File < Stream
      include PayloadIO # _write, _read

      attr_accessor :file, :stream

      # Writes a Request payload String.
      def _send_request request_payload
        _write request_payload, stream
      ensure
        close if ::File.pipe?(file)
      end

      # Returns a Request payload String.
      def _receive_request stream
        _read stream
      end

      # one-way; no Response.
      def _send_response stream
        nil
      end

      # one-way; no Response.
      def _receive_response opaque
        nil
      end

      # !SLIDE
      # File Transport Support
    
      def stream
        @stream ||=
          ::File.open(file, "w+")
      end

      # !SLIDE
      # Process (receive) requests from a file.

      def serve_file!
        ::File.open(file, "r") do | stream |
          serve_stream! stream, nil
        end
      end

      # !SLIDE
      # Named Pipe Server

      def prepare_pipe_server!
        _log :prepare_pipe_server!
        unless ::File.exist? file
          system(cmd = "mkfifo #{file.inspect}") or raise "cannot run #{cmd.inspect}"
        end
      end

      def run_pipe_server!
        _log :run_pipe_server!
        @running = true
        while @running
          serve_file!
        end
      end

      # !SLIDE END
    end
    # !SLIDE END
  end
end

