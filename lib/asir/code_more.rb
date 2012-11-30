module ASIR
  # !SLIDE
  # Code More
  #
  # Help encode/decode and resolve receiver class.
  module CodeMore
    include ObjectResolving # resolve_object()
    include CodeBlock # encode_block!, decode_block!

    attr_accessor :receiver_name

    def encode_more!
      obj = encode_block! # may self.dup
      unless ::String === @receiver_class
        obj ||= self.dup # dont dup twice.
        if ::Module === @receiver
          obj.receiver_name = true
          obj.receiver = @receiver.name
        end
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
        # pp [ :decode_more!, self ]
        @receiver_class = resolve_object(@receiver_class)
        @receiver = resolve_object(@receiver) if @receiver_name
        unless @receiver_class === @receiver
          raise Error, "receiver #{@receiver.class.name} is not a #{@receiver_class}" 
        end
      end
      self
    end

    # If receiver is a Module (i.e. class or module message),
    #   Returns [ name of the Module, :'.' ]
    # Otherwise
    #   Returns [ name of the receiver's Class, :'#' ]
    def message_kind
      case
      when ::String === @receiver_class
        [ @receiver_class, :'.' ]
      when ::Module === @receiver
        [ @receiver.name, :'.' ]
      else
        [ @receiver_class.name, :'#' ]
      end
    end

    # Returns "Module.selector" if receiver is Module.
    # Returns "Class#selector" if receiver is an instance.
    def description
      x = message_kind
      "#{x[0]}#{x[1]}#{@selector}"
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
  # !SLIDE END
end

