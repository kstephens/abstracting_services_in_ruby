# !SLIDE :capture_code_output true
# Synchronous HTTP service

require 'example_helper'
require 'asir/transport/webrick'
require 'asir/coder/base64'
require 'asir/coder/zlib'
begin
  Email.asir.transport = t =
    ASIR::Transport::Webrick.new(:uri => "http://localhost:31913/")
  t.encoder =
    ASIR::Coder::Chain.new(:encoders =>
                           [ASIR::Coder::Marshal.new,
                            ASIR::Coder::Base64.new, ])
  server_process do
    t.around_serve_message = lambda do | trans, state, &blk |
      begin
        $stderr.puts "### Before message #{trans.message_count.inspect}"
        blk.call
      ensure
        $stderr.puts "### After message #{trans.message_count.inspect}"
      end
    end
    t.prepare_server!
    t.run_server!
  end
  pr Email.asir.send_email(:pdf_invoice,
                             :to => "user@email.com",
                             :customer => @customer)
  sleep 2
rescue Object => err
  $stderr.puts "#{err.inspect}\n#{err.backtrace * "\n"}"
ensure
  t.close rescue nil; sleep 3
  server_kill
end

# !SLIDE END
# EXPECT: : client process
# EXPECT: : server process
# EXPECT: : Email.send_mail :pdf_invoice
# EXPECT: : pr: :ok
# EXPECT: ### Before message nil
# EXPECT: ### After message 1

