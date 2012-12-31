# !SLIDE :capture_code_output true
# One-way, named pipe service

require 'example_helper'
begin
  File.unlink(service_pipe = "#{__FILE__}.service.pipe") rescue nil
  Email.asir.transport = t =
    ASIR::Transport::File.new(:file => service_pipe)
  t.encoder =
    ASIR::Coder::Yaml.new
  server_process do
    t.prepare_server!
    t.run_server!
  end
  pr Email.asir.send_email(:pdf_invoice, :to => "user@email.com", :customer => @customer)
ensure
  t.close; sleep 1; server_kill
end

# !SLIDE END
# EXPECT: : client process
# EXPECT: : server process
# EXPECT: : Email.send_mail :pdf_invoice
# EXPECT: : pr: nil

