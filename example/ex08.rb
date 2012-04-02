# !SLIDE :capture_code_output true
# One-way, named pipe service with invalid signature

require 'example_helper'
begin
  File.unlink(service_pipe = "service.pipe") rescue nil
  Email.client.transport = t =
    ASIR::Transport::File.new(:file => service_pipe)
  t.encoder =
    ASIR::Coder::Chain.new(:encoders =>
      [ ASIR::Coder::Marshal.new,
        s = ASIR::Coder::Sign.new(:secret => 'abc123'),
        ASIR::Coder::Yaml.new,
      ])
  t.prepare_pipe_server!
  server_process do
    t.run_pipe_server!
  end
  s.secret = 'I do not know the secret! :('
  pr Email.client.send_email(:pdf_invoice, :to => "user@email.com", :customer => @customer)
ensure
  t.close; sleep 1; server_kill
end

# !SLIDE END
# EXPECT: : client process
# EXPECT: : server process
# EXPECT!: : Email.send_mail :pdf_invoice
# EXPECT: : pr: nil

