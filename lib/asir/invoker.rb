module ASIR
  # !SLIDE
  # Invoker
  #
  # Invokes the Message or Exception on behalf of a Transport.
  class Invoker
    include Initialization, AdditionalData

    def invoke! message, transport
      message.invoke!
    end
  end
end

