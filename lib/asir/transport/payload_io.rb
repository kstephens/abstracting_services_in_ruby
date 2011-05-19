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
        _log { "  _write size = #{payload.size}" }
        stream.puts payload.size
        _log { "  _write #{payload.inspect}" }
        stream.write payload
        stream.puts EMPTY_STRING
        stream.flush
        stream
      end

      def _read stream
        size = stream.readline.chomp.to_i
        _log { "  _read  size = #{size.inspect}" }
        payload = stream.read(size)
        _log { "  _read  #{payload.inspect}" }
        stream.readline
        payload
      end

      def _read_line_and_expect! stream, regexp
        _log { "_read_line_and_expect! #{stream} #{regexp.inspect} ..." }
        line = stream.readline
        _log { "_read_line_and_expect! #{stream} #{regexp.inspect} =~ #{line.inspect}" }
        unless match = regexp.match(line)
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
        @stream = nil
      end

      # !SLIDE resume
    end
  end
end
