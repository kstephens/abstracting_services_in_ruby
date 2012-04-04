# !SLIDE :capture_code_output true
# Synchronous HTTP service on Rack under WEBrick

gem 'rack'
require 'example_helper'
require 'asir/transport/rack'
require 'asir/coder/base64'
begin
  Email.client.transport = t =
    ASIR::Transport::Rack.new(:uri => "http://localhost:31924/")
  t.encoder =
    ASIR::Coder::Chain.new(:encoders =>
                           [ASIR::Coder::Marshal.new,
                            ASIR::Coder::Base64.new, ])
  server_process do
    t.prepare_server!
    t.run_server!
  end; sleep 2
  pr Email.client.send_email(:pdf_invoice,
                             :to => "user@email.com",
                             :customer => @customer)
  sleep 2
rescue Object => err
  $stderr.puts "#{err.inspect}\n#{err.backtrace * "\n"}"
ensure
  t.close rescue nil; sleep 3
  server_kill; sleep 2
end

# !SLIDE END
# EXPECT: : client process
# EXPECT: : server process
# EXPECT: : Email.send_mail :pdf_invoice
# EXPECT: : pr: :ok

