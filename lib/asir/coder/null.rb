require 'asir/coder'

module ASIR
  class Coder
    # !SLIDE
    # Null Coder
    # Always encode/decode as nil.
    class Null < self
      def _encode obj
        nil
      end

      def _decode obj
        nil
      end

      # Completely stateless.
      def dup; self; end
    end
    # !SLIDE END
  end
end

