require 'example_helper'
require 'asir/transport/zmq'
require 'asir/coder/marshal'
begin
  Email.asir.transport = t =
    ASIR::Transport::Zmq.new(:uri => "tcp://localhost:31000") # "/asir"
  t.one_way = true
  t.encoder = ASIR::Coder::Marshal.new
  pr Email.asir.send_email(:pdf_invoice,
                             :to => "user@email.com",
                             :customer => @customer)
ensure
  t.close rescue nil
end

