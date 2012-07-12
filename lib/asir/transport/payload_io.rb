module ASIR
  class Transport
    # !SLIDE
    # Payload IO for Transport
    #
    # Framing
    # * Header line containing the number of bytes in the payload.
    # * The payload bytes.
    # * Blank line.
    # * Footer.
    module PayloadIO
      class UnexpectedResponse < Error; end

      HEADER = "# asir_payload_size: "
      FOOTER = "\n# asir_payload_end"

      def _write payload, stream
        stream.write HEADER
        stream.puts payload.size
        stream.write payload
        stream.puts FOOTER
        stream.flush
        stream
      end

      def _read stream
        size = /\d+$/.match(stream.readline.chomp)[0].to_i # HEADER (size)
        payload = stream.read(size)
        stream.readline # FOOTER
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
