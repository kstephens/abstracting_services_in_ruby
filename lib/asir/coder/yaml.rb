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
        yaml_dump(obj)
      end

      def _decode obj
        case obj = ::YAML::load(obj)
        when Message, Result
          obj.decode_more!
        else
          obj
        end
      end

      attr_accessor :yaml_options
      case RUBY_VERSION
      when /^1\.8/
        def yaml_dump obj
          ::YAML::dump obj
        end
      else
        def yaml_dump obj
          ::YAML::dump(obj, nil, yaml_options || EMPTY_HASH)
        end
      end
    end # class
  end # class
end # module

if defined? ::Psych
  class Psych::Visitors::YAMLTree
    alias :binary_without_option? :binary?
    def binary? string
      return false if @options[:never_binary]
      result =
        string.index("\x00") ||
        string.count("\x00-\x7F", "^ -~\t\r\n").fdiv(string.length) > 0.3
      unless @options[:ASCII_8BIT_ok]
        result ||= string.encoding == Encoding::ASCII_8BIT
      end
      result
    end
  end
end

