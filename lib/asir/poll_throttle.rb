require 'asir'

module ASIR
  module PollThrottle
    # Polls block until non-nil block result.
    # If non-nil, retry after sleeping for s sec, which starts at opts[:min_sleep].
    # Will retry up to opts[:max_tries] times, if defined.
    # s is multiplied by opts[:mul_sleep] and incremented by opts[:inc_sleep], if defined.
    # s is limited by opts[:max_sleep].
    # s is adjusted by s * opts[:rand_sleep], if defined.
    # Returns result yield from block.
    def poll_throttle opts = nil
      opts ||= { }
      i = 0
      s = opts[:min_sleep] ||= 0.01
      opts[:max_sleep] ||= 60
      # opts[:inc_sleep] ||= 1
      # opts[:mul_sleep] ||= 1.5
      result = nil
      loop do
        i += 1
        unless (result = yield).nil?
          return result
        end
        if x = opts[:max_tries] and i >= x
          return result
        end
        this_s = s
        if x = opts[:rand_sleep]
          this_s += s * rand * x
        end
        if opts[:verbose]
          $stderr.puts "  #{self}: poll_throttle: sleeping for #{this_s} sec"
        end
        sleep this_s if this_s > 0
        if x = opts[:mul_sleep]
          s *= x
        end
        if x = opts[:inc_sleep]
          s += x
        end
        if x = opts[:max_sleep] and s > x
          s = x
        end
        if x = opts[:min_sleep] and s < x
          s = x
        end
      end
      result
    end
  end
end

