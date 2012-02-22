
module ASIR
  # !SLIDE
  # Message
  #
  # Encapsulate the Ruby message from the Client to be handled by the Service.
  class Message
    include AdditionalData, Identity, CodeMore
    attr_accessor :receiver, :receiver_class, :selector, :arguments, :block
    attr_accessor :result

    def initialize r, s, a, b
      @receiver, @selector, @arguments = r, s, a
      @block = b if b
      @receiver_class = @receiver.class
    end

    def invoke!
      @result = Result.new(self, @result = @receiver.__send__(@selector, *@arguments))
    rescue *Error::Unforwardable.unforwardable => exc
      @result = Result.new(self, nil, Error::Unforwardable.new(exc))
    rescue ::Exception => exc
      @result = Result.new(self, nil, exc)
    end

    # Optional: Specifies the Numeric seconds or absolute Time to delay the Message until actual processing.
    attr_accessor :delay
  end
  # !SLIDE END
end
