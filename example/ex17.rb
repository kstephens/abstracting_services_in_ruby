# !SLIDE :capture_code_output true
# Buffered asynchronous beanstalkd service with delay option

require 'example_helper'
require 'asir/transport/beanstalk'
require 'asir/transport/buffer'
begin
  t =
    ASIR::Transport::Beanstalk.new(:address => '127.0.0.1', :port => 30917)
  t.encoder =
    ASIR::Coder::Marshal.new
  t.start_conduit!; sleep 1
  DelayedService.asir.transport =
    t0 = ASIR::Transport::Buffer.new(:transport => t)
  t0.pause!
  server_process do
    t.prepare_server!
    t.run_server!
  end
  pr [ :paused?, t0.paused?, :at, Time.now.iso8601(2) ]
  pr DelayedService.asir.
    _configure{|req, p| req.delay = 5}.
    do_it(Time.now)
  sleep 2
  pr [ :resuming, :size, t0.size, :at, Time.now.iso8601(2) ]
  t0.resume!
  pr [ :paused?, t0.paused?, :size, t0.size, :at, Time.now.iso8601(2) ]
  pr [ :resumed, :size, t0.size, :at, Time.now.iso8601(2) ]
  sleep 7
rescue Object => err
  $stderr.puts "#{err.inspect}\n#{err.backtrace * "\n"}"
ensure
  t.close; sleep 1; server_kill; sleep 1
  t.stop_conduit!
end

# !SLIDE END
# EXPECT: : client process
# EXPECT: : server process
# EXPECT: DelayedService.do_it => :ok
# EXPECT: : pr: nil

