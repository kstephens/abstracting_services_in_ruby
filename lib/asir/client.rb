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

    module CommonMethods
      def client_options &blk
        client._configure(&blk)
      end
    end

    module ModuleMethods
      include CommonMethods
      # Proxies are cached for Module/Class methods because serialization will not include
      # Transport.
      def client
        @_asir_client ||=
          ASIR::Client::Proxy.new(self)
      end
    end

    module InstanceMethods
      include CommonMethods
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
      attr_accessor :receiver, :transport

      def transport
        @transport ||=
          Transport::Local.new
      end

      # Accept messages as a proxy for thje receiver.
      # Blocks are used represent a "continuation" for the Response.
      def send selector, *arguments, &block
        request = Request.new(receiver, selector, arguments, &block)
        request = @before_send_request.call(request) if @before_send_request
        @__configure.call(request) if @__configure
        result = transport.send_request(request)
        result
      end
      # Accept all other messages to be encoded and transported to a service.
      alias :method_missing :send


      # !SLIDE
      # Proxy Configuration.

      # A Proc to call with the Request object before sending to transport#send_request(request).
      # Must return a Request object.
      attr_accessor :before_send_request

      # A Proc to call with the Request object before sending to transport#send_request(request).
      # See #_configure.
      attr_accessor :__configure

      # Returns a new Client proxy with a block to be called with the Request.
      # This block can configure additional options of the Request before
      # it is sent to the Transport.
      def _configure &blk
        client = self.dup
        client.__configure = blk
        client
      end
      alias :_options :_configure

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
