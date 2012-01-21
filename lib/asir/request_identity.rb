require 'asir/uuid'
require 'thread' # Mutex

module ASIR
  # !SLIDE
  # Request Identity
  #
  module RequestIdentity
    attr_accessor :identifier, :timestamp, :client # optional

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
