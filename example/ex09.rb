# !SLIDE :capture_code_output true
# Socket service

require 'example_helper'
require 'asir/coder/marshal'
require 'asir/transport/tcp_socket'
begin
  Email.client.transport = t = 
    ASIR::Transport::TcpSocket.new(:port => 30901)
  t.encoder = 
    ASIR::Coder::Marshal.new
  
  t.prepare_socket_server!
  child_pid = Process.fork do 
    t.run_socket_server!
  end
  sleep 1
  
  pr Email.client.send_email(:pdf_invoice, 
                             :to => "user@email.com", :customer => @customer)
ensure
  t.close; sleep 1
  Process.kill 9, child_pid
end

