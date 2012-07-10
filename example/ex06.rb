# !SLIDE :capture_code_output true
# One-way, named pipe service

$stderr.puts "  #{$$} at #{__FILE__}:#{__LINE__}"

require 'example_helper'
begin
  File.unlink(service_pipe = "service.pipe") rescue nil
  Email.client.transport = t =
    ASIR::Transport::File.new(:file => service_pipe)
  t.encoder =
    ASIR::Coder::Yaml.new
  server_process do
    t.prepare_server!
    t.run_server!
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

