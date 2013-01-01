require 'asir/transport/stream'
require 'asir/transport/payload_io'
require 'asir/fifo'

module ASIR
  class Transport
    # !SLIDE
    # File Transport
    #
    # Send Message to a file.
    # Can be used as a log or named pipe service.
    class File < Stream
      include PayloadIO # _write, _read
      attr_accessor :file, :mode, :perms, :stream
      attr_accessor :result_file, :result_fifo

      def initialize opts = nil; @one_way = true; super; end

      # If not one_way, create a result_file fifo.
      def send_message message
        result_file_created = false
        unless one_way || message.one_way
          result_file = message[:result_file] ||= self.result_file ||
            begin
              message.create_identifier!
              "#{self.file}-result-#{message.identifier}"
            end
          unless ::File.exist?(result_file) and result_fifo
            ::ASIR::Fifo.mkfifo(result_file, perms)
            result_file_created = true
          end
        end
        super
      ensure
        if result_file_created
          ::File.unlink(result_file) rescue nil
        end
      end

      def _send_message state
        _write(state.message_payload, state.out_stream || stream, state)
      ensure
        close if file && ::File.pipe?(file)
      end

      def _receive_message state
        state.message_payload = _read(state.in_stream || stream, state)
      end

      # Send result to result_file.
      def _send_result state
        with_result_file state do | result_file |
          ::File.open(result_file, "a+") do | stream |
            _write(state.result_payload, stream, state)
          end
        end
      end

      # Receive result from result_file.
      def _receive_result state
        with_result_file state do | result_file |
          ::File.open(result_file, "r") do | stream |
            state.result_payload = _read(stream, state)
          end
        end
      end

      def with_result_file state
        unless one_way || (message = state.message).one_way
          if result_file = message[:result_file] || self.result_file
            yield result_file
          end
        end
      end

      def needs_message_identifier? m
        @needs_message_identifier || ! one_way || ! m.one_way
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
          _serve_stream! stream, ! one_way
        end
      end

      # !SLIDE
      # Named Pipe Server

      def prepare_server!
        unless ::File.exist? file
          ::ASIR::Fifo.mkfifo(file, perms)
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

