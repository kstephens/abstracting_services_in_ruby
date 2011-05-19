module ASIR
  # !SLIDE
  # Response
  #
  # Encapsulate the response returned to the Client.
  class Response
    include AdditionalData
    attr_accessor :request, :result, :exception
    attr_accessor :identifier, :server, :timestamp # optional

    def initialize req, res = nil, exc = nil
      @request, @result, @exception = 
        req, res, (exc && EncapsulatedException.new(exc))
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
