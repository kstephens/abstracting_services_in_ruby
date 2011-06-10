
module ASIR
  # !SLIDE
  # Request
  #
  # Encapsulate the request message from the Client to be handled by the Service.
  class Request
    include ObjectResolving, AdditionalData
    attr_accessor :receiver, :receiver_class, :selector, :arguments
    attr_accessor :response
    attr_accessor :identifier, :client, :timestamp # optional

    # Optional: Specifies the Numeric seconds or absolute Time to delay the Request until actual processing.
    attr_accessor :delay 

    def initialize r, s, a
      @receiver, @selector, @arguments = r, s, a
      @receiver_class = @receiver.class
    end

    def invoke!
      @response = Response.new(self, @result = @receiver.__send__(@selector, *@arguments))
    rescue ::Exception => exc
      @response = Response.new(self, nil, exc)
    end

    # !SLIDE
    # Request Identifier

    def create_identifier!
      @identifier ||= 
        "#{@@counter += 1}-#{@@uuid_pid == $$ ? @@uuid ||= ::ASIR::UUID.generate : @@uuid = ::ASIR::UUID.generate}".freeze
    end
    @@counter ||= 0; @@uuid ||= nil; @@uuid_pid = nil

    def create_timestamp!
      @timestamp ||= 
        ::Time.now.gmtime
    end

    # !SLIDE
    # Help encode/decode receiver

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
    # !SLIDE END
  end
  # !SLIDE END
end

require 'asir/uuid'
