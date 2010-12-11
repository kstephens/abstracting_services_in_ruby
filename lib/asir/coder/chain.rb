module ASIR
  class Coder
    # !SLIDE
    # Chain Coder
    # Chain multiple Coders as one.
    #
    # @@@
    #   request  --> | e1 | --> | e2 | --> | eN | --> 
    #   response <-- | d1 | <-- | d2 | <-- | dN | <--
    # @@@
    class Chain < self
      attr_accessor :encoders

      def _encode obj
        encoders.each do | e |
          obj = e.dup.encode(obj)
        end
        obj
      end

      def _decode obj
        encoders.reverse_each do | e |
          obj = e.dup.decode(obj)
        end
        obj
      end
    end
  end
end

