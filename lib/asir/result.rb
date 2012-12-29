module ASIR
  # !SLIDE
  # Result
  #
  # Encapsulate the result returned to the Client.
  class Result
    include AdditionalData, Identity, CodeMore::Result
    attr_accessor :message, :result, :exception
    # Optional: Opaque data about the server that processed the Message.
    attr_accessor :server

    def initialize msg, res = nil, exc = nil
      @message = msg; @result = res
      @exception = exc && EncapsulatedException.new(exc)
      @identifier = @message.identifier
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
      # Map backtrace Location objects to Strings to support RBX.
      @exception_backtrace = exc.backtrace.map{|x| x.to_s}
    end

    def invoke!
      raise resolve_object(@exception_class), @exception_message, @exception_backtrace
    end

    def construct!
      invoke!
    rescue ::Exception => exc
      exc
    end
  end
  # !SLIDE END
end
