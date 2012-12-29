# !SLIDE :capture_code_output true
# Two-way, Named Pipe service

require 'example_helper'
begin
  File.unlink(service_log = "#{__FILE__}.service.pipe") rescue nil
  Email.asir.transport = t =
    ASIR::Transport::File.new(:file => service_log, :one_way => false, :result_fifo => true)
  t.encoder =
    ASIR::Coder::Yaml.new(:yaml_options => { :ASCII_8BIT_ok => true })
  server_process do
    t.prepare_server!
    t.run_server!
  end
  sleep 1
  pr Email.asir.send_email(:pdf_invoice,
                             :to => "user@email.com",
                             :customer => @customer)
ensure
  t.close rescue nil; sleep 1; server_kill
end

# !SLIDE END
# EXPECT: : client process
# EXPECT: : server process
# EXPECT: : Email.send_mail :pdf_invoice
# EXPECT: : pr: :ok
