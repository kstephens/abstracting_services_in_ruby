module ASIR
  # !SLIDE
  # Coder
  #
  # Define encoding and decoding for Messages and Results along a Transport.
  class Coder
    include Log, Initialization

    def encode obj
      _encode obj
    end

    def decode obj
      obj and _decode obj
    end

    # Coder subclasses:
    def _subclass_responsibility *args
      raise "subclass responsibility"
    end
    alias :_encode :_subclass_responsibility
    alias :_decode :_subclass_responsibility
  end
  # !SLIDE END
end

