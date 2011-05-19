module ASIR
  # !SLIDE
  # Mixin Client support to any Module
  #
  # Extend Module with #client proxy support.
  module Client
    def self.included target
      super
      target.extend Methods if Module === target
      target.send(:include, Methods) if Class === target
    end
    
    module Methods
      def client
        @_asir_client ||=
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

      # A Proc to call with the Request object before sending to transport#send_request(request).
      attr_accessor :before_send_request

      def transport
        @transport ||=
          Transport::Local.new
      end
      
      # Accept all other messages to be encoded and transported to a service.
      def method_missing selector, *arguments
        raise ArgumentError, "block given" if block_given?
        _log { "method_missing #{selector.inspect} #{arguments.inspect}" }
        request = Request.new(receiver, selector, arguments)
        request = @before_send_request.call(request) if @before_send_request
        result = transport.send_request(request)
        result
      end

      # !SLIDE
      # Configuration Callbacks

      def initialize *args
        super
        key = Module === @receiver ? @receiver : @receiver.class
        (@@config_callbacks[key] || 
         @@config_callbacks[key.name] || 
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
