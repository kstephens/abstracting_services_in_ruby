module ASIR
  # Generic API error.
  class Error < ::Exception
    # Subclass should override method.
    class SubclassResponsibility < self; end

    # Unsupported Feature.
    class Unsupported < self; end

    # Unimplemented Feature.
    class Unimplemented < self; end

    # Requested Stop.
    class Terminate < self; end

    # Unrecoverable Errors.
    class Unrecoverable < self
      def self.modules;    @@modules; end
      def self.modules= x; @@modules = x; end
      @@modules ||= [ self ]
    end

    # Fatal Errors.
    class Fatal < Unrecoverable; end

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
      def self.modules;    @@modules; end; alias :unforwardable :modules
      def self.modules= x; @@modules = x; end; alias :unforwardable= :modules=
      @@modules ||= [
        ::SystemExit,
        ::SystemStackError,
        ::NoMemoryError,
        ::Interrupt,
        ::SignalException,
        Error::Terminate,
        Error::Unrecoverable,
      ]
    end
  end
end
