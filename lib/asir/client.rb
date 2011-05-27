module ASIR
  # !SLIDE
  # Mixin Client support to any Module
  #
  # Extend Module with #client proxy support.
  module Client
    def self.included target
      super
      target.extend ModuleMethods if Module === target
      target.send(:include, InstanceMethods) if Class === target
    end
    
    module ModuleMethods
      # Proxies are cached for Module/Class methods because serialization will not include
      # Transport.
      def client
        @_asir_client ||=
          ASIR::Client::Proxy.new(self)
      end
    end

    module InstanceMethods
      # Proxies are not cached in instances because receiver is to be serialized by
      # its Transport's coder.
      def client
        ASIR::Client::Proxy.new(self)
      end
    end

    # !SLIDE
    # Client Proxy
    #
    # Provide client interface proxy to a service.
    class Proxy
      include Log
      
      attr_accessor :receiver, :transport

      # A Proc to call with the Request object before sending to transport#send_request(request).
      attr_accessor :before_send_request

      def transport
        @transport ||=
          Transport::Local.new
      end
      
      # Accept all other messages to be encoded and transported to a service.
      def method_missing selector, *arguments
        raise Error::Unsupported, "block given" if block_given?
        request = Request.new(receiver, selector, arguments)
        request = @before_send_request.call(request) if @before_send_request
        result = transport.send_request(request)
        result
      end

      # !SLIDE
      # Configuration Callbacks

      def initialize rcvr
        key = Module === (@receiver = rcvr) ? @receiver : @receiver.class
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
