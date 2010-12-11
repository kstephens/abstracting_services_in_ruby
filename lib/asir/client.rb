module ASIR
  # !SLIDE
  # Mixin Client support to any Module
  #
  # Extend Module with #client proxy support.
  module Client
    def self.included target
      super
      target.extend ModuleMethods if Module === target
    end
    
    module ModuleMethods
      def client
        @client ||=
          ASIR::Client::Proxy.new(:receiver => self)
      end
    end

    # !SLIDE
    # Client Proxy
    #
    # Provide client interface proxy to a service.
    class Proxy
      include Log, Initialization
      
      attr_accessor :receiver, :transport

      def transport
        @transport ||=
          Transport::Local.new
      end
      
      # Accept all other messages to be encoded and transported to a service.
      def method_missing selector, *arguments
        raise ArgumentError, "block given" if block_given?
        _log { "method_missing #{selector.inspect} #{arguments.inspect}" }
        request = Request.new(receiver, selector, arguments)
        result = transport.send_request(request)
        result
      end

      # !SLIDE
      # Configuration Callbacks

      def initialize *args
        super
        (@@config_callbacks[@receiver] || 
         @@config_callbacks[@receiver.name] || 
         @@config_callbacks[nil] ||
         IDENTITY_LAMBDA).call(self)
      end

      @@config_callbacks ||= { }
      def self.config_callbacks
        @@config_callbacks
      end

      # !SLIDE END
    end
    # !SLIDE END
  end
  # !SLIDE END
end
