require 'asir'

module ASIR
  class Coder
    # Generic Proc-based coder.
    class Proc < self
      # Procs that take one argument.
      attr_accessor :encoder, :decoder

      def _encode obj
        @encoder.call(obj)
      end
      def _decode obj
        @decoder.call(obj)
      end
    end
  end
end

