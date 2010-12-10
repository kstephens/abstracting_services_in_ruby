require 'yaml'

module ASIR
  class Coder
    # !SLIDE
    # YAML Coder
    # Use YAML for encode/decode.
    class Yaml < self
      def _encode obj
        case obj
        when Request
          obj = obj.encode_receiver!
        end
        ::YAML::dump(obj)
      end

      def _decode obj
        case obj = ::YAML::load(obj)
        when Request
          obj.decode_receiver!
        else
          obj
        end
      end
    end # class
  end # class
end # module

