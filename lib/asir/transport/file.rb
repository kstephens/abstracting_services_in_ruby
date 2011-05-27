require 'asir/transport/stream'
require 'asir/transport/payload_io'

module ASIR
  class Transport
    # !SLIDE
    # File Transport
    #
    # Send Request one-way to a file.
    # Can be used as a log or named pipe service.
    class File < Stream
      include PayloadIO # _write, _read

      attr_accessor :file, :mode, :perms, :stream

      # Writes a Request payload String.
      def _send_request request, request_payload
        _write request_payload, stream
      ensure
        close if ::File.pipe?(file)
      end

      # Returns a Request payload String.
      def _receive_request stream, additional_data
        [ _read(stream), nil ]
      end

      # one-way; no Response.
      def _send_response request, response, response_payload, stream, request_state
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
          begin
            stream = ::File.open(file, mode || "w+")
            ::File.chmod(perms, file) rescue nil if @perms 
            after_connect!(stream) if respond_to?(:after_connect!)
            stream
          end
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
        _log [ :prepare_pipe_server!, file ]
        unless ::File.exist? file
          system(cmd = "mkfifo #{file.inspect}") or raise "cannot run #{cmd.inspect}"
          ::File.chmod(perms, file) rescue nil if perms 
        end
      end

      def run_pipe_server!
        _log [ :run_pipe_server!, file ]
        with_server_signals! do
          @running = true
          while @running
            serve_file!
          end
        end
      end

      # !SLIDE END
    end
    # !SLIDE END
  end
end

