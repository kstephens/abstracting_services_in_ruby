# !SLIDE :capture_code_output true
# Socket service

require 'example_helper'
begin
  Email.asir.transport = t =
    ASIR::Transport::TcpSocket.new(:port => 30909)
  t.encoder =
    ASIR::Coder::Marshal.new
  server_process do
    t.prepare_server!
    t.run_server!
  end
  pr Email.asir.send_email(:pdf_invoice,
                             :to => "user@email.com", :customer => @customer)
ensure
  t.close; sleep 1; server_kill
end

# !SLIDE END
# EXPECT: : client process
# EXPECT: : server process
# EXPECT: : Email.send_mail :pdf_invoice
# EXPECT: : pr: :ok

