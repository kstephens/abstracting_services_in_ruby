# Use the Marshal and Base64 coders in prob-4.rb

$: << File.expand_path("../../../lib", __FILE__)
require 'asir/transport/http'
require 'asir/coder/base64'

require 'math_service'
MathService.send(:include, ASIR::Client)

port = 3001
begin
  t = ASIR::Transport::HTTP.new(:uri => "http://localhost:#{port}/")
  t._log_enabled = true
  c = t.encoder = ASIR::Coder::Chain.new(:encoders =>
                                         [ 
                                          ASIR::Coder::Marshal.new,
                                          ASIR::Coder::Base64.new,
                                         ])
  c._log_enabled = true

  server_pid = Process.fork do
    t.setup_webrick_server!
    t.start_webrick_server!
  end
  sleep 1 # wait for server to start

  MathService.client.transport = t
  MathService.client.sum([1, 2, 3])
rescue Exception => err
  $stderr.puts "ERROR: #{err.inspect}\n#{err.backtrace * "\n"}"
ensure
  Process.kill(9, server_pid)
end

