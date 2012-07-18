# !SLIDE :capture_code_output true
# One-way Resque service.

require 'rubygems'
gem 'resque'
require 'example_helper'
require 'asir/transport/resque'
begin
  t = ASIR::Transport::Resque.new(:port => 31925,
                              :encoder => ASIR::Coder::Marshal.new)
  # Control throttling of Resque::Worker inside ASIR::Transport::Resque
  t.throttle = {
    # :verbose => true,
    :min_sleep => 0.0,
    :max_sleep => 2.0,
    :inc_sleep => 0.1,
    :mul_sleep => 1.5,
    :rand_sleep => 0.1,
  }
  t.start_conduit!; sleep 1
  server_process do
    t.prepare_server!
    t.run_server!
  end
  UnsafeService.asir.transport = t
  pr UnsafeService.asir.do_it(":ok")
rescue ::Exception => err
  $stderr.puts "### #{$$}: ERROR: #{err.inspect}\n  #{err.backtrace * "\n  "}"
  raise
ensure
  sleep 5
  t.close rescue nil; sleep 1; server_kill
  t.stop_conduit!
end

# !SLIDE END
# EXPECT: : client process
# EXPECT: : server process
# EXPECT: UnsafeService.do_it => :ok
# EXPECT: : pr: nil
# EXPECT!: ERROR
