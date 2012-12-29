module ASIR
  # Module to create FIFO/Named Pipes.
  module Fifo
    case (RUBY_ENGINE rescue 'UNKNOWN')
    when /jruby/i
      def mkfifo file, perms = nil
        mode ||= 0644
        system(cmd = "mkfifo #{file.inspect}") or raise "cannot run #{cmd.inspect}"
        ::File.chmod(perms, file) rescue nil if perms
        true
      end
    else
      require "mkfifo"
      def mkfifo file, perms = nil
        mode ||= 0644
        ::File.mkfifo(file)
        ::File.chmod(perms, file) rescue nil if perms
        true
      end
    end
    extend self
  end
end


