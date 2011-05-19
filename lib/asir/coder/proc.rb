require 'asir'

module ASIR
  class Coder
    # Generic Proc-based coder.
    class Proc < self
      attr_accessor :encode, :decode

      def _encode obj
        @encode.call(obj)
      end
      def _decode obj
        @decode.call(obj)
      end
    end
  end
end

