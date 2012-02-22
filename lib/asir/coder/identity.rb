require 'asir/coder'

module ASIR
  class Coder
    # !SLIDE
    # Identity Coder
    # Perform no encode/decode.
    class Identity < self
      def _encode obj
        obj
      end

      def _decode obj
        obj
      end

      # Completely stateless.
      def dup; self; end
    end
  end
end

