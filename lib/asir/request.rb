
module ASIR
  # !SLIDE
  # Request
  #
  # Encapsulate the request message from the Client to be handled by the Service.
  class Request
    include AdditionalData, RequestIdentity, CodeMore
    attr_accessor :receiver, :receiver_class, :selector, :arguments
    attr_accessor :response

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
  end
  # !SLIDE END
end
