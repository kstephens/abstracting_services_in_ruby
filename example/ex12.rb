# !SLIDE :capture_code_output true
# Asynchronous beanstalkd service

require 'example_helper'
require 'asir/transport/beanstalk'
require 'asir/coder/zlib'
begin
  Email.asir.transport = t =
    ASIR::Transport::Beanstalk.new(:address => '127.0.0.1', :port => 30904)
  t.encoder =
    ASIR::Coder::Chain.new(:encoders =>
                           [ ASIR::Coder::Marshal.new,
                            ASIR::Coder::Zlib.new, ])
  t.start_conduit!; sleep 1
  pr Email.asir.send_email(:pdf_invoice,
                             :to => "user@email.com", :customer => @customer)
  sleep 2
  server_process do
    t.prepare_server!
    t.run_server!
  end
rescue Object => err
  $stderr.puts "#{err.inspect}\n#{err.backtrace * "\n"}"
ensure
  t.close; sleep 3; server_kill; sleep 2
  t.stop_conduit!
end

# !SLIDE END
# EXPECT: : client process
# EXPECT: : server process
# EXPECT: : Email.send_mail :pdf_invoice
# EXPECT: : pr: nil

