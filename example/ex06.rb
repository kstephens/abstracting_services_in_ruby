# !SLIDE :capture_code_output true
# One-way, named pipe service

require 'example_helper'
begin
  File.unlink(service_pipe = "service.pipe") rescue nil
  Email.client.transport = t =
    ASIR::Transport::File.new(:file => service_pipe)
  t.encoder =
    ASIR::Coder::Yaml.new
  t.prepare_pipe_server!
  server_process do
    t.run_pipe_server!
  end
  pr Email.client.send_email(:pdf_invoice, :to => "user@email.com", :customer => @customer)
ensure
  t.close; sleep 1; server_kill
end

# !SLIDE END
# EXPECT: : client process
# EXPECT: : server process
# EXPECT: : Email.send_mail :pdf_invoice
# EXPECT: : pr: nil

