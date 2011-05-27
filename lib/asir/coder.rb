module ASIR
  # !SLIDE
  # Coder 
  #
  # Define encoding and decoding for Requests and Responses along a Transport.
  class Coder
    include Log, Initialization

    def encode obj
      _encode obj
    end

    def decode obj
      obj and _decode obj
    end

    def _subclass_responsibility *args
      raise "subclass responsibility"
    end
    alias :_encode :_subclass_responsibility
    alias :_decode :_subclass_responsibility


    # Coder subclasses.
    # ...
    # !SLIDE pause

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
    # !SLIDE resume
  end
  # !SLIDE END
end

