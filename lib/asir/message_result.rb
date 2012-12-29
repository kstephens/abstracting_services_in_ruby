module ASIR
  # !SLIDE
  # MessageResult
  #
  # Encapsulate the Message, Result and their payloads.
  # This is passed between Transport#send_request, #receive_request, #send_response, #receive_response.
  class MessageResult
    include Initialization
    attr_accessor :message, :result
    attr_accessor :message_payload, :result_payload
    attr_accessor :message_opaque, :result_opaque
    attr_accessor :in_stream, :out_stream
  end
end

