require 'asir/transport'

module Asir
  class Transport
    # Conduit service support.
    module Conduit
      def start_conduit! options = nil
        opts = { :fork => true }
        opts.update(options) if options
        _log { "start_conduit! #{self}" } if @verbose >= 1
        in_fork = opts[:fork]
        raise "already running #{@conduit_pid} #{@conduit_cmd}" if @conduit_pid
        if in_fork
          @conduit_pid = ::Process.fork do
          _log { "start_conduit! #{self} starting pid=#{$$.inspect}" } if @verbose >= 2
            _start_conduit!
            raise "Could not exec"
          end
          _log { "start_conduit! #{self} started pid=#{@conduit_pid.inspect}" } if @verbose >= 2
        else
          _start_conduit!
        end
        self
      end

      def stop_conduit! opts = nil
        if @conduit_pid
          _log { "stop_conduit! #{self} pid=#{@conduit_pid.inspect}" } if @verbose >= 1
          ::Process.kill( (opts && opts[:signal]) || 'TERM', @conduit_pid)
          ::Process.waitpid @conduit_pid
          # File.unlink @redis_conf
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
