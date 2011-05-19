module ASIR
  # !SLIDE
  # Request
  #
  # Encapsulate the request message from the Client to be handled by the Service.
  class Request
    include ObjectResolving, AdditionalData
    attr_accessor :receiver, :receiver_class, :selector, :arguments, :result
    attr_accessor :identifier, :client, :timestamp # optional

    def initialize r, s, a
      @receiver, @selector, @arguments = r, s, a
      @receiver_class = @receiver.class
    end

    def invoke!
      Response.new(self, @result = @receiver.__send__(@selector, *@arguments))
    rescue Exception => exc
      Response.new(self, nil, exc)
    end

    # !SLIDE
    # Request Identifier

    def create_identifier!
      @identifier ||= 
        "#{@@counter += 1}-#{$$}-#{Thread.current.object_id}-#{@@uuid ||= File.read("/proc/sys/kernel/random/uuid").chomp!}"
    end
    @@counter ||= 0; @@uuid ||= nil

    # !SLIDE
    # Help encode/decode receiver

    def encode_receiver!
      unless String === @receiver_class
        case @receiver
        when Module
          obj = self.dup
          obj.receiver = @receiver.name
          obj.receiver_class = @receiver_class.name
          return obj
        end
      end
      self
    end

    def decode_receiver!
      if String === @receiver_class
        @receiver_class = resolve_object(@receiver_class)
        @receiver = resolve_object(@receiver)
        unless @receiver_class === @receiver
          raise Error, "receiver #{@receiver.class.name} is not a #{@receiver_class}" 
        end
      end
      self
    end
    # !SLIDE END
  end
  # !SLIDE END
end

