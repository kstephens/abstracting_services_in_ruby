require 'asir/uuid'

module ASIR
  # !SLIDE
  # Message Identity
  #
  module Identity
    attr_accessor :identifier, :timestamp

    # Creates a thread-safe unique identifier.
    def create_identifier!
      @identifier ||= ::ASIR::UUID.counter_uuid
    end

    # Creates a timestamp.
    def create_timestamp!
      @timestamp ||= ::Time.now.gmtime
    end
  end
end
