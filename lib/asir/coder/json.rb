require 'asir'

module ASIR
  class Coder
    # !SLIDE
    # JSON Coder
    #
    # Note: Symbols are not handled.
    # The actual JSON expression is wrapped with an Array.
    class JSON < self
      def _encode obj
        [ obj ].to_json
      end

      def _decode obj
        ::JSON.parser.new(obj).
          parse.first
      end
    end
    # !SLIDE END
  end
end

if RUBY_PLATFORM =~ /java/
require 'json'
else
require 'json/ext'
end

