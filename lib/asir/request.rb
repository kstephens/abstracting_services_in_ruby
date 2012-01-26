
module ASIR
  # !SLIDE
  # Request
  #
  # Encapsulate the request message from the Client to be handled by the Service.
  class Request
    include AdditionalData, RequestIdentity, CodeMore
    attr_accessor :receiver, :receiver_class, :selector, :arguments, :block
    attr_accessor :response
    # Optional: Opaque data about the Client that created the Request.
    attr_accessor :client
    # Optional: Specifies the Numeric seconds or absolute Time to delay the Request until actual processing.
    attr_accessor :delay 

    def initialize r, s, a, b
      @receiver, @selector, @arguments = r, s, a
      @block = b if b
      @receiver_class = @receiver.class
    end

    def invoke!
      @response = Response.new(self, @result = @receiver.__send__(@selector, *@arguments))
    rescue *Error::Unforwardable.unforwardable => exc
      @response = Response.new(self, nil, Error::Unforwardable.new(exc))
    rescue ::Exception => exc
      @response = Response.new(self, nil, exc)
    end
  end
  # !SLIDE END
end
