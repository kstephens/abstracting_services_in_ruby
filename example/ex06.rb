# !SLIDE :capture_code_output true
# One-way, named pipe service

require 'example_helper'
begin
  File.unlink(service_fifo = "service.fifo") rescue nil

  Email.client.transport = 
    ASIR::Transport::File.new(:file => service_fifo)
  Email.client.transport.encoder = 
    ASIR::Coder::Yaml.new

  Email.client.transport.prepare_fifo_server!
  child_pid = Process.fork do 
    Email.client.transport.run_fifo_server!
  end

  pr Email.client.send_email(:giant_pdf_invoice, :to => "user@email.com", :customer => @customer)
ensure
  Email.client.transport.close
  sleep 1
  Process.kill 9, child_pid
  File.unlink(service_fifo) rescue nil
end

