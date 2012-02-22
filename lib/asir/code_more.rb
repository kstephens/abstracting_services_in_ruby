module ASIR
  # !SLIDE
  # Code More
  #
  # Help encode/decode and resolve receiver class.
  module CodeMore
    include ObjectResolving # resolve_object()

    def encode_more!
      obj = nil
      if @block && ! ::String === @block_code
        obj ||= self.dup
        obj.block_code = obj.block.to_ruby if obj.block.respond_to(:to_ruby) # ruby2ruby
        obj.block = nil
      end
      unless ::String === @receiver_class
        obj ||= self.dup
        obj.receiver = @receiver.name if ::Module === @receiver
        obj.receiver_class = @receiver_class.name
        if resp = obj.result and resp.message == self
          resp.message = obj
        end
      end
      obj || self
    end

    def decode_more!
      if ::String === @block_code
        @block ||= eval(@block_code); @block_code = nil
      end
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
