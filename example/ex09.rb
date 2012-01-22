# !SLIDE :capture_code_output true
# Socket service

require 'example_helper'
begin
  Email.client.transport = t = 
    ASIR::Transport::TcpSocket.new(:port => 30901)
  t.encoder = 
    ASIR::Coder::Marshal.new
  
  t.prepare_server!
  server_process do
    t.run_server!
  end
  
  pr Email.client.send_email(:pdf_invoice, 
                             :to => "user@email.com", :customer => @customer)
ensure
  t.close; sleep 1
  server_kill
end

# !SLIDE END
# EXPECT: : client process
# EXPECT: : server process
# EXPECT: : Email.send_mail :pdf_invoice
# EXPECT: : pr: :ok

