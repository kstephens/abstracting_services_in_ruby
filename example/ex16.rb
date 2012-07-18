# !SLIDE :capture_code_output true
# Asynchronous beanstalkd service with delay option

require 'example_helper'
require 'asir/transport/beanstalk'
begin
  DelayedService.asir.transport = t =
    ASIR::Transport::Beanstalk.new(:address => '127.0.0.1', :port => 30916)
  t.encoder =
    ASIR::Coder::Marshal.new
  t.start_conduit!; sleep 1
  server_process do
    t.prepare_server!
    t.run_server!
  end
  pr DelayedService.asir.
    _configure{|req, p| req.delay = 5}.
    do_it(Time.now)
  sleep 10
rescue Object => err
  $stderr.puts "#{err.inspect}\n#{err.backtrace * "\n"}"
ensure
  t.close; sleep 1
  server_kill; sleep 1
  t.stop_conduit!
end

# !SLIDE END
# EXPECT: : client process
# EXPECT: : server process
# EXPECT: DelayedService.do_it => :ok
# EXPECT: : pr: nil

