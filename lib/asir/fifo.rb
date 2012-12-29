module ASIR
  # Module to create FIFO/Named Pipes.
  module Fifo
    begin
      require 'ffi'
      module LIBC
        extend FFI::Library
        ffi_lib FFI::Library::LIBC
        attach_function :mkfifo, [ :string, :long ], :int
      end
      def mkfifo file, perms = nil
        perms ||= 0600
        if LIBC.mkfifo(file, perms) < 0
          raise "mkfifo(#{file.inspect}, #{'0%o' % perms}) failed"
        end
        true
      end
    rescue ::Exception => exc
      def mkfifo file, perms = nil
        perms ||= 0600
        system(cmd = "mkfifo #{file.inspect}") or raise "cannot run #{cmd.inspect}"
        ::File.chmod(perms, file) rescue nil if perms
        true
      end
    end
    extend self
  end
end


