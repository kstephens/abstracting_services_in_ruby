module ASIR
  # !SLIDE
  # Generic retry behavior
  module RetryBehavior
    # Maximum trys.
    attr_accessor :try_max
    # Initial amount of seconds to sleep between each try.
    attr_accessor :try_sleep
    # Amount of seconds to increment sleep between each try.
    attr_accessor :try_sleep_increment
    # Maxinum amount of seconds to sleep between each try.
    attr_accessor :try_sleep_max

    # Yields:
    #   :try, n_try - for each attempt.
    #   :rescue, exc - for any rescued exception.
    #   :retry, exc - before each retry.
    #   :failed, last_exc - when too many retrys occurred.
    def with_retry
      n_try = 0
      sleep_secs = try_sleep
      result = done = last_exception = nil
      begin
        n_try += 1
        result = yield :try, n_try
        done = true
      rescue *Error::Unrecoverable.modules
        raise
      rescue *Error::Unforwardable.modules
        raise
      rescue ::Exception => exc
        last_exc = exc
        yield :rescue, exc
        if ! try_max || try_max > n_try
          yield :retry, exc
          if sleep_secs
            sleep sleep_secs if sleep_secs > 0
            sleep_secs += try_sleep_increment if try_sleep_increment
            sleep_secs = try_sleep_max if try_sleep_max && sleep_secs > try_sleep_max
          end
          retry
        end
      end
      unless done
        unless yield :failed, last_exc
          exc = last_exc
          raise RetryError, "Retry failed: #{exc.inspect}", exc.backtrace
        end
      end
      result
    end
    class RetryError < Error; end
  end # module
  # !SLIDE END
end # module ASIR

