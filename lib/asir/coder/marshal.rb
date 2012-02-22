module ASIR
  class Coder
    # !SLIDE
    # Marshal Coder
    # Use Ruby Marshal for encode/decode.
    class Marshal < self
      def _encode obj
        ::Marshal.dump(obj)
      end

      def _decode obj
        ::Marshal.load(obj)
      end
    end # class
    # !SLIDE END
  end # class
end # module
