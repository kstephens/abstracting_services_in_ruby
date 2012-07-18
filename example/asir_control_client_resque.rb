require 'example_helper'
gem 'resque'
require 'asir/transport/resque'
require 'asir/coder/marshal'
begin
  Email.asir.transport = t =
    ASIR::Transport::Resque.new
  t.one_way = true
  t.encoder = ASIR::Coder::Marshal.new
  pr Email.asir.send_email(:pdf_invoice,
                             :to => "user@email.com",
                             :customer => @customer)
ensure
  t.close rescue nil
end

