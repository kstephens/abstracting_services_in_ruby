require 'thread'

module ASIR
# Provides an RFC4122-compliant random (version 4) UUID service.
module UUID
  # Return an RFC4122-compliant random (version 4) UUID,
  # represented as a string of 36 characters.
  #
  # Possible (but unlikely!) return value:
  #   "e29fc859-8d6d-4c5d-aa5a-1ab726f4a192".
  #
  # Possible exceptions:
  #   Errno::ENOENT
  #
  PROC_SYS_FILE = "/proc/sys/kernel/random/uuid".freeze
  case
  when File.exist?(PROC_SYS_FILE)
    def new_uuid
      File.read(PROC_SYS_FILE).chomp!
    end
  when (gem 'uuid' rescue nil)
    require 'uuid'
    def new_uuid
      ::UUID.generate
    end
  else
    def new_uuid
      raise "Unimplemented"
    end
  end
  UUID_REGEX = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\Z/i

  def process_uuid
    @@process_uuid_mutex.synchronize do
      if @@pid != $$
        @@pid = $$
        @@process_uuid = nil
      end
      @@process_uuid ||= new_uuid
    end
  end
  @@pid = @@process_uuid = nil
  @@process_uuid_mutex = Mutex.new

  def counter_uuid
    i = @@counter_mutex.synchronize do
      @@counter += 1
    end
    "#{i}-#{process_uuid}"
  end
  @@counter ||= 0
  @@counter_mutex = Mutex.new
  COUNTER_UUID_REGEX = /\A[0-9]+-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\Z/i

  # Returns a unique counter_uuid for a Thread.
  # thr defaults to Thread.current.
  def thread_uuid thr = nil
    thr ||= Thread.current
    @@thread_uuid_mutex.synchronize do
      thr[:'ASIR::UUID.thread_uuid'] ||= counter_uuid
    end
  end
  @@thread_uuid_mutex = Mutex.new

  extend self
  alias :generate :new_uuid # DEPRECATED
end
end


