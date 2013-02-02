require 'asir/transport'

module Asir
  class Transport
    # Conduit service support.
    module Conduit
      attr_accessor :conduit_options, :conduit_pid

      def start_conduit! options = nil
        opts = @conduit_options ||= {}
        opts.update(:fork => true)
        opts.update(options) if options
        _log { "start_conduit! #{self}" } if @verbose >= 1
        in_fork = opts[:fork]
        raise "already running #{@conduit_pid} #{@conduit_cmd}" if @conduit_pid
        if in_fork
          @conduit_pid = ::Process.fork do
            _log { "start_conduit! #{self} starting pid=#{$$.inspect}" } if @verbose >= 2
            _close_stdio!
            _start_conduit!
            raise "Could not exec"
          end
          _log { "start_conduit! #{self} started pid=#{@conduit_pid.inspect}" } if @verbose >= 2
          if pid_file = (@conduit_options || EMPTY_HASH)[:pid_file]
            ::File.open(pid_file, "w") { | fh | fh.puts @conduit_pid }
          end
        else
          _close_stdio!
          _start_conduit!
        end
        self
      end

      def _close_stdio!
        n = ::File.open("/dev/null", "w+")
        [ STDIN, STDOUT, STDERR, $stdin, $stdout, $stderr ].each do | io |
          io.reopen(n) rescue nil
        end
      end	

      def conduit_pid
        if ! @conduit_pid and pid_file = (@conduit_options || EMPTY_HASH)[:pid_file]
          @conduit_pid = (::File.read(pid_file).to_i rescue nil)
        end
        @conduit_pid
      end

      def stop_conduit! opts = nil
        if conduit_pid
          _log { "stop_conduit! #{self} pid=#{@conduit_pid.inspect}" } if @verbose >= 1
          ::Process.kill( (opts && opts[:signal]) || 'TERM', @conduit_pid)
          if pid_file = (@conduit_options || EMPTY_HASH)[:pid_file]
            ::File.unlink(pid_file) rescue nil
          end
          ::Process.waitpid @conduit_pid
        end
        self
      ensure
        @conduit_pid = nil
      end

      def _start_conduit!
        raise Error::SubclassResponsibility
      end
    end
  end
end
