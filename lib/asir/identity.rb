require 'asir/uuid'

module ASIR
  # !SLIDE
  # Message Identity
  #
  module Identity
    attr_accessor :identifier, :timestamp

    # Optional: Opaque data about the Client that created the Message.
    attr_accessor :client

    # Optional: Opaque data about the Service that handled the Result.
    attr_accessor :server

    # Creates a thread-safe unique identifier.
    def create_identifier!
      @identifier ||= ::ASIR::UUID.counter_uuid
    end

    # Creates a timestamp.
    def create_timestamp!
      @timestamp ||= 
        ::Time.now.gmtime
    end
  end
end
