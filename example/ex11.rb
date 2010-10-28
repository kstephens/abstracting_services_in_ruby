# !SLIDE :capture_code_output true
# Socket service with local recovery.

require 'example_helper'
begin
  Email.client.transport =
    ASIR::Transport::Recovery.new(:transports => 
                                  [
                                   tcp = ASIR::Transport::TcpSocket.new(:port => 30903),
                                   ASIR::Transport::Local.new,
                                  ])
  tcp.encoder = 
    ASIR::Coder::Marshal.new

  pr Email.client.send_email(:giant_pdf_invoice, 
                             :to => "user@email.com", :customer => @customer)

  tcp.prepare_socket_server!
  child_pid = Process.fork do 
    tcp.run_socket_server!
  end

  pr Email.client.send_email(:giant_pdf_invoice, 
                             :to => "user2@email.com", :customer => @customer)
  
ensure
  tcp.close; sleep 1
  Process.kill 9, child_pid

end

