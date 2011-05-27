module ASIR
  class Transport
    # !SLIDE
    # Payload IO for Transport
    #
    # Framing
    # * Line containing the number of bytes in the payload.
    # * The payload bytes.
    # * Blank line.
    module PayloadIO
      class UnexpectedResponse < Error; end

      def _write payload, stream
        stream.puts payload.size
        stream.write payload
        stream.puts EMPTY_STRING
        stream.flush
        stream
      end

      def _read stream
        size = stream.readline.chomp.to_i
        payload = stream.read(size)
        stream.readline
        payload
      end

      def _read_line_and_expect! stream, regexp
        line = stream.readline
        unless match = regexp.match(line)
          _log { "_read_line_and_expect! #{stream} #{regexp.inspect} !~ #{line.inspect}" }
          raise UnexpectedResponse, "expected #{regexp.inspect}, received #{line.inspect}"
        end
        match
      end

      # !SLIDE pause
      def close
        if @stream
          _before_close! stream if respond_to?(:_before_close!)
          @stream.close
        end
      ensure
        @stream = nil unless Channel === @stream
      end

      # !SLIDE resume
    end
  end
end
