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
        parser = ::JSON.parser.new(obj)
        ary = parser.parse
        ary.first
      end

      # Completely stateless.
      def dup; self; end
    end
    # !SLIDE END
  end
end

if RUBY_PLATFORM =~ /java/
require 'json'
else
require 'json/ext'
end

