require 'asir/uuid'
require 'thread' # Mutex

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
      @identifier ||= 
        @@identifier_mutex.synchronize do
          if @@uuid_pid != $$
            @@uuid_pid = $$
            @@uuid = nil
          end
          "#{@@counter += 1}-#{@@uuid ||= ::ASIR::UUID.generate}".freeze
        end
    end
    @@counter ||= 0; @@uuid ||= nil; @@uuid_pid = nil; @@identifier_mutex ||= Mutex.new

    # Creates a timestamp.
    def create_timestamp!
      @timestamp ||= 
        ::Time.now.gmtime
    end
  end
end
