require 'yaml'

module ASIR
  class Coder
    # !SLIDE
    # YAML Coder
    # Use YAML for encode/decode.
    class Yaml < self
      def _encode obj
        case obj
        when Message, Result
          obj = obj.encode_more!
        end
        ::YAML::dump(obj)
      end

      def _decode obj
        case obj = ::YAML::load(obj)
        when Message, Result
          obj.decode_more!
        else
          obj
        end
      end
    end # class
  end # class
end # module

