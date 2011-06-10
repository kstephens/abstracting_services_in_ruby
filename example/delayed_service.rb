require 'asir'
require 'time'

module DelayedService
  include ASIR::Client
  def self.do_it(t0)
    dt = Time.now - t0
    result = 5 <= dt && dt <= 6 ? :ok : :not_delayed
    puts "DelayedService.do_it(#{t0.iso8601}) dt=#{dt.inspect} #{result.inspect}"
    $stderr.puts "DelayedService.do_it => #{result.inspect}"
    raise "Failed" unless result == :ok
    result 
  end
end

