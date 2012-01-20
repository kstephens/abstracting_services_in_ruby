module ASIR
  # !SLIDE
  # Code More
  #
  # Help encode/decode and resolve receiver class.
  module CodeMore
    include ObjectResolving # resolve_object()

    def encode_more!
      unless ::String === @receiver_class
        obj = self.dup
        obj.receiver = @receiver.name if ::Module === @receiver
        obj.receiver_class = @receiver_class.name
        if resp = obj.response and resp.request == self
          resp.request = obj
        end
        return obj
      end
      self
    end

    def decode_more!
      if ::String === @receiver_class
        @receiver_class = resolve_object(@receiver_class)
        @receiver = resolve_object(@receiver) if ::Module === @receiver_class
        unless @receiver_class === @receiver
          raise Error, "receiver #{@receiver.class.name} is not a #{@receiver_class}" 
        end
      end
      self
    end
  end
end
