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
      rescue ::Exception
        require 'pp'
        msg = "#{self}: failed to encode: #{$!.inspect}:\n  #{PP.pp(obj, '')}"
        $stderr.puts msg
        raise Error, msg
      end

      def _decode obj
        case obj = ::YAML::load(obj)
        when Message, Result
          obj.decode_more!
        else
          obj
        end
      end

      # Completely stateless.
      def dup; self; end
    end # class
  end # class
end # module

