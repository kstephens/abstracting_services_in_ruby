require 'asir'

require 'base64'

module ASIR
  class Coder
    class Base64 < self
      def _encode obj
        raise TypeError unless String === obj
        ::Base64.encode64(obj)
      end
      def _decode obj
        raise TypeError unless String === obj
        ::Base64.decode64(obj)
      end
    end
  end
end

