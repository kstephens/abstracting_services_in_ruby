require 'asir'

require 'zlib'

module ASIR
  class Coder
    class Zlib < self
      attr_accessor :compression_level

      def _encode obj
        raise TypeError unless String === obj
        ::Zlib::Deflate.deflate(obj, @compression_level || ::Zlib::DEFAULT_COMPRESSION)
      end
      def _decode obj
        raise TypeError unless String === obj
        ::Zlib::Inflate.inflate(obj)
      end

      # Completely stateless.
      def dup; self; end
    end
  end
end

