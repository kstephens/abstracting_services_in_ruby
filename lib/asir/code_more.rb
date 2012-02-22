module ASIR
  # !SLIDE
  # Code More
  #
  # Help encode/decode and resolve receiver class.
  module CodeMore
    include ObjectResolving # resolve_object()
    include CodeBlock # encode_block!, decode_block!

    def encode_more!
      obj = encode_block! # may self.dup
      unless ::String === @receiver_class
        obj ||= self.dup # dont dup twice.
        obj.receiver = @receiver.name if ::Module === @receiver
        obj.receiver_class = @receiver_class.name
        if resp = obj.result and resp.message == self
          resp.message = obj
        end
      end
      obj || self
    end

    def decode_more!
      decode_block!
      if ::String === @receiver_class
        @receiver_class = resolve_object(@receiver_class)
        @receiver = resolve_object(@receiver) if ::Module === @receiver_class
        unless @receiver_class === @receiver
          raise Error, "receiver #{@receiver.class.name} is not a #{@receiver_class}" 
        end
      end
      self
    end

    # Mixin for Result.
    module Result
      def encode_more!
        @message = @message.encode_more! if @message
        self
      end

      def decode_more!
        @message = @message.decode_more! if @message
        self
      end
    end
  end
end
