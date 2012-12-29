require 'asir/transport/stream'
require 'asir/transport/payload_io'

module ASIR
  class Transport
    # !SLIDE
    # File Transport
    #
    # Send Message one-way to a file.
    # Can be used as a log or named pipe service.
    class File < Stream
      include PayloadIO # _write, _read
      attr_accessor :file, :mode, :perms, :stream

      def initialize opts = nil; @one_way = true; super; end

      # Writes a Message payload String.
      def _send_message message_result
        _write(message_result.message_payload, message_result.out_stream || stream, message_result)
      ensure
        close if file && ::File.pipe?(file)
      end

      # Returns a Message payload String.
      def _receive_message message_result
        message_result.message_payload = _read(message_result.in_stream || stream, message_result)
      end

      # one-way; no Result.
      def _send_result message_result
        nil
      end

      # one-way; no Result.
      def _receive_result message_result
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
      # Process (receive) messages from a file.

      def serve_file!
        ::File.open(file, "r") do | stream |
          @running = true
          _serve_stream! stream, nil # One-way: no result stream.
        end
      end

      # !SLIDE
      # Named Pipe Server

      def prepare_server!
        unless ::File.exist? file
          system(cmd = "mkfifo #{file.inspect}") or raise "cannot run #{cmd.inspect}"
          ::File.chmod(perms, file) rescue nil if perms
        end
      end
      alias :prepare_pipe_server! :prepare_server!

      def run_server!
        with_server_signals! do
          @running = true
          while @running
            serve_file!
          end
        end
      end
      alias :run_pipe_server! :run_server!

      # !SLIDE END
    end
    # !SLIDE END
  end
end

