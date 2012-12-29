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
      def asir_options &blk
        asir._configure(&blk)
      end
      alias_method :"#{ASIR::Config.client_method}_options", :asir_options if ASIR::Config.client_method
    end

    module ModuleMethods
      include CommonMethods
      # Proxies are cached for Module/Class methods because serialization will not include
      # Transport.
      def asir
        @_asir ||= ASIR::Client::Proxy.new(self, self)
      end
      alias_method ASIR::Config.client_method, :asir if ASIR::Config.client_method
    end

    module InstanceMethods
      include CommonMethods
      # Proxies are not cached in instances because receiver is to be serialized by
      # its Transport's Coder.
      def asir
        proxy = self.class.asir.dup
        proxy.receiver = self
        proxy
      end
      alias_method ASIR::Config.client_method, :asir if ASIR::Config.client_method
    end

    # !SLIDE
    # Client Proxy
    #
    # Provide client interface proxy to a service.
    class Proxy
      attr_accessor :receiver, :receiver_class

      # Accept messages as a proxy for the receiver.
      # Blocks are used represent a "continuation" for the Result.
      def send selector, *arguments, &block
        message = Message.new(@receiver, selector, arguments, block, self)
        message = @before_send_message.call(message) if @before_send_message
        @__configure.call(message, self) if @__configure
        transport.send_message(message) # => result
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
      #
      # Call sequence:
      #
      #   proxy.__configure.call(message, proxy).
      def _configure &blk
        proxy = @receiver == @receiver_class ? self.dup : self
        proxy.__configure = blk
        proxy
      end
      alias :_options :_configure

      # !SLIDE
      # Configuration Callbacks

      def initialize rcvr, rcvr_class
        @receiver = rcvr
        @receiver_class = rcvr_class
        _configure!
      end

      def _configure!
        key = @receiver_class
        (@@config_callbacks[key] ||
         @@config_callbacks[key.name] ||
         @@config_callbacks[nil] ||
         IDENTITY_LAMBDA).call(self)
        self
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
