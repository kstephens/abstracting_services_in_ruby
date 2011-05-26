require 'yaml'

module ASIR
  class Coder
    # !SLIDE
    # YAML Coder
    # Use YAML for encode/decode.
    class Yaml < self
      def _encode obj
        case obj
        when Request, Response
          obj = obj.encode_more!
        end
        ::YAML::dump(obj)
=begin
      rescue ::Exception
        require 'pp'
        raise Error, "#{self}: failed to encode: #{$!.inspect}:\n  #{PP.pp(obj, '')}"
=end
      end

      def _decode obj
        case obj = ::YAML::load(obj)
        when Request, Response
          obj.decode_more!
        else
          obj
        end
      end
    end # class
  end # class
end # module

