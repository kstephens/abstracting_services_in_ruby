require 'example_helper'
require 'asir/transport/http'
require 'asir/coder/marshal'
begin
  Email.client.transport = t =
    ASIR::Transport::HTTP.new(:uri => "http://localhost:30000/asir")
  t.encoder = ASIR::Coder::Marshal.new
  pr Email.client.send_email(:pdf_invoice,
                             :to => "user@email.com",
                             :customer => @customer)
ensure
  t.close rescue nil
end

