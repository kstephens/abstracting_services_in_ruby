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
    def self.generate
      File.read(PROC_SYS_FILE).chomp!
    end
  when (gem 'uuid' rescue nil)
    require 'uuid'
    def self.generate
      ::UUID.generate
    end
  else
    def self.generate
      raise "Unimplemented"
    end
  end
end
end


