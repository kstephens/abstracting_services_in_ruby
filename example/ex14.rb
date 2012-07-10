# !SLIDE :capture_code_output true
# Synchronous HTTP service on instance methods.

require 'example_helper'
require 'asir/transport/webrick'
require 'asir/coder/base64'
begin
  MyClass.client.transport = t =
    ASIR::Transport::Webrick.new(:uri => "http://localhost:30914/")
  t.encoder =
    ASIR::Coder::Chain.new(:encoders =>
                           [ ASIR::Coder::Marshal.new,
                             ASIR::Coder::Base64.new, ])
  server_process do
    t.prepare_server!
    t.run_server!
  end
  pr MyClass.new("abc123").client.size
  sleep 2
rescue Object => err
  $stderr.puts "#{err.inspect}\n#{err.backtrace * "\n"}"
ensure
  t.close; sleep 3; server_kill
end

# !SLIDE END
# EXPECT: : client process
# EXPECT: : server process
# EXPECT: : pr: 6

