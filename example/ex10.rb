# !SLIDE :capture_code_output true
# Socket service with forwarded exception.

require 'example_helper'
begin
  Email.client.transport = t =
    ASIR::Transport::TcpSocket.new(:port => 30902)
  t.encoder = 
    ASIR::Coder::Marshal.new

  t.prepare_server!
  server_process do
    t.run_server!
  end
  
  pr Email.client.do_raise("Raise Me!")
rescue Exception => err
  pr [ :exception, err ]
ensure
  t.close; sleep 1
  server_kill
end

# !SLIDE END
# EXPECT: : client process
# EXPECT: : server process
# EXPECT: : pr: [:exception, #<RuntimeError: Raise Me!>]
