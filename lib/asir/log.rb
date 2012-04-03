module ASIR
  # !SLIDE
  # Diagnostic Logging
  #
  # Logging mixin.
  module Log
    attr_accessor :_logger

    def self.included target
      super
      target.send(:extend, ClassMethods)
    end

    @@enabled = false
    def self.enabled
      @@enabled
    end
    def self.enabled= x
      @@enabled = x
    end

    module ClassMethods
      def _log_enabled= x
        (Thread.current[:'ASIR::Log.enabled'] ||= { })[self] = x
      end
      def _log_enabled?
        (Thread.current[:'ASIR::Log.enabled'] ||= { })[self]
      end
    end

    def _log_enabled= x
      @_log_enabled = x
    end

    def _log_enabled?
      ASIR::Log.enabled || 
        @_log_enabled || 
        self.class._log_enabled?
    end

    def _log msg = nil
      return unless _log_enabled?
      msg ||= yield if block_given?
      msg = String === msg ? msg : _log_format(msg)
      msg = "  #{$$} #{Module === self ? self : self.class} #{msg}"
      case @_logger
      when Proc
        @_logger.call msg
      when IO
        @_logger.puts msg
      else
        $stderr.puts msg
      end
      nil
    end

    def _log_result msg
      _log { 
        msg = String === msg ? msg : _log_format(msg);
        "#{msg} => ..." }
      result = yield
      _log { "#{msg} => \n    #{result.inspect}" }
      result
    end

    def _log_format obj
      case obj
      when Exception
        msg = "#{obj.inspect}"
        msg << "\n    #{obj.backtrace * "\n    "}" if false
        msg
      when Array
        obj.map { | x | _log_format x } * ", "
      else
        obj.inspect
      end
    end
  end # module
end # module



