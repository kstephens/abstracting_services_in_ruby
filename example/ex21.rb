# !SLIDE :capture_code_output true
# Bi-directional ZMQ service.

require 'example_helper'
require 'asir/transport/zmq'
begin
  zmq = ASIR::Transport::Zmq.new(:port => 31920,
                                 :encoder => ASIR::Coder::Marshal.new,
                                 :one_way => false)
  server_process do
    zmq.prepare_server!
    zmq.run_server!
  end
  UnsafeService.asir.transport = t = zmq
  pr UnsafeService.asir.do_it(":ok")
rescue ::Exception => err
  $stderr.puts "### #{$$}: ERROR: #{err.inspect}\n  #{err.backtrace * "\n  "}"
  raise
ensure
  zmq.close rescue nil; sleep 1; server_kill
end

# !SLIDE END
# EXPECT: : client process
# EXPECT: : server process
# EXPECT: UnsafeService.do_it => :ok
# EXPECT: : pr: :ok
# EXPECT!: ERROR
