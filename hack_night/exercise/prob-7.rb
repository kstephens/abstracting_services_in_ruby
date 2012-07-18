# Use the Marshal and Base64 coders with the HTTP transport.

$: << File.expand_path("../../../lib", __FILE__)
require 'asir_transport_http'
require 'asir_coder_base64'

require 'math_service'
MathService.send(:include, ASIR::Client)

port = 3001
begin
  t = ASIR::Transport::HTTP.new(:uri => "http://localhost:#{port}")
  t._log_enabled = true

  c = t.encoder = ASIR::Coder::# ???.new(:encoders => ???)
  c._log_enabled = true

  server_pid = Process.fork do
    t.setup_server!
    t.start_server!
  end
  sleep 1 # wait for server to start

  MathService.asir.transport = t
  MathService.asir.sum([1, 2, 3])

rescue Exception => err
  $stderr.puts "ERROR: #{err.inspect}\n#{err.backtrace * "\n"}"

ensure
  sleep 1 # wait for server to finish
  Process.kill(9, server_pid)
end

