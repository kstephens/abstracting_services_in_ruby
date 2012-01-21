module ASIR
  # !SLIDE
  # Response
  #
  # Encapsulate the response returned to the Client.
  class Response
    include AdditionalData, RequestIdentity
    attr_accessor :request, :result, :exception
    # Optional: Opaque data about the server that processed the Request.
    attr_accessor :server

    def initialize req, res = nil, exc = nil
      @request = req; @result = res
      @exception = exc && EncapsulatedException.new(exc)
      @identifier = @request.identifier
    end

    def encode_more!
      @request = @request.encode_more! if @request
      self
    end

    def decode_more!
      @request = @request.decode_more! if @request
      self
    end
  end
  # !SLIDE END

  # !SLIDE
  # Encapsulated Exception
  #
  # Encapsulates exceptions raised in the Service.
  class EncapsulatedException
    include ObjectResolving, AdditionalData
    attr_accessor :exception_class, :exception_message, :exception_backtrace

    def initialize exc
      @exception_class     = exc.class.name
      @exception_message   = exc.message
      @exception_backtrace = exc.backtrace
    end

    def invoke!
      raise resolve_object(@exception_class), @exception_message, @exception_backtrace
    end
  end
  # !SLIDE END
end
