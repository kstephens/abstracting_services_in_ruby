module ASIR
  # !SLIDE
  # Client support for any Module
  #
  # Extend Module with #client proxy support.
  module Client
    # !SLIDE
    # Client Mixin
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
        @_asir_client ||= ASIR::Client::Proxy.new(self)
      end
    end

    module InstanceMethods
      include CommonMethods
      # Proxies are not cached in instances because receiver is to be serialized by
      # its Transport's Coder.
      def client
        ASIR::Client::Proxy.new(self)
      end
    end

    # !SLIDE
    # Client Proxy
    #
    # Provide client interface proxy to a service.
    class Proxy
      attr_accessor :receiver

      # Accept messages as a proxy for the receiver.
      # Blocks are used represent a "continuation" for the Result.
      def send selector, *arguments, &block
        message = Message.new(@receiver, selector, arguments, block, self)
        message = @before_send_message.call(message) if @before_send_message
        @__configure.call(message) if @__configure
        result = transport.send_message(message)
        result
      end
      # Accept all other messages to be encoded and transported to a service.
      alias :method_missing :send

      # !SLIDE
      # Client Transport
      attr_accessor :transport

      def transport
        @transport ||= Transport::Local.new
      end

      # !SLIDE
      # Proxy Configuration

      # A Proc to call with the Message object before sending to transport#send_message(message).
      # Must return a Message object.
      attr_accessor :before_send_message

      # If true, this Message is one-way, even if the Transport is bi-directional.
      attr_accessor :_one_way

      # A Proc to call with the Message object before sending to transport#send_message(message).
      # See #_configure.
      attr_accessor :__configure

      # Returns a new Client Proxy with a block to be called with the Message.
      # This block can configure additional options of the Message before
      # it is sent to the Transport.
      def _configure &blk
        proxy = self.dup
        proxy.__configure = blk
        proxy
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
