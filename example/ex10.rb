# !SLIDE :capture_code_output true
# Socket service with forwarded exception.

require 'example_helper'
begin
  Email.client.transport = t =
    ASIR::Transport::TcpSocket.new(:port => 30902)
  t.encoder = 
    ASIR::Coder::Marshal.new

  t.prepare_socket_server!
  child_pid = Process.fork do 
    t.run_socket_server!
  end
  sleep 1
  
  pr Email.client.do_raise("Raise Me!")
rescue Exception => err
  pr [ :exception, err ]
ensure
  t.close; sleep 1
  Process.kill 9, child_pid
end

# !SLIDE END
# EXPECT: : client process
# EXPECT: : pr: [:exception, #<RuntimeError: Raise Me!>]
