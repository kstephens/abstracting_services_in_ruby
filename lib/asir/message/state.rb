module ASIR
  class Message
  # !SLIDE
  # Message::State
  #
  # Encapsulate the Message, Result and their payloads and other state.
  # This is passed between Transport#send_request, #receive_request, #send_response, #receive_response.
  class State
    include Initialization
    attr_accessor :message, :result
    attr_accessor :message_payload, :result_payload
    attr_accessor :message_opaque, :result_opaque
    attr_accessor :in_stream, :out_stream
    attr_accessor :additional_data
  end
  end
end

