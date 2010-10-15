# !SLIDE :capture_code_output true
# Socket service

require 'example_helper'
begin
  Email.client.transport =
    ASIR::Transport::TcpSocket.new(:port => 30901)
  Email.client.transport.encoder = 
    ASIR::Coder::Marshal.new
  
  Email.client.transport.prepare_socket_server!
  child_pid = Process.fork do 
    Email.client.transport.run_socket_server!
  end
  
  pr Email.client.send_email(:giant_pdf_invoice, :to => "user@email.com", :customer => @customer)
ensure
  Email.client.transport.close
  sleep 1
  Process.kill 9, child_pid
end

