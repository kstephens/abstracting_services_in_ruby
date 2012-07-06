module ASIR
  # Generic API error.
  class Error < ::Exception
    # Subclass should override method.
    class SubclassResponsibility < self; end

    # Unsupported Feature.
    class Unsupported < self; end

    # Unimplemented Feature
    class Unimplemented < self; end

    # Requested Stop.
    class Terminate < self; end

    # Unforwardable Exception.
    #
    # This encapsulates an Exception that should never be
    # forwarded and re-thrown directly in the client.
    # E.g.: SystemExit, Interrupt.
    class Unforwardable < self
      attr_accessor :original
      def initialize msg, original = nil, *args
        if ::Exception === msg
          original ||= msg
          msg = "#{original.class.name} #{msg.message}"
        end
        @original = original
        super(msg)
        self.set_backtrace original && original.backtrace
      end
      def self.unforwardable;    @@unforwardable; end
      def self.unforwardable= x; @@unforwardable = x; end
      @@unforwardable ||= [ ::SystemExit, ::Interrupt ]
    end
  end
end
