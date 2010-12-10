# Write a ASIR::Transport::HTTP class that uses HTTP::Client for transport send_response and receive_response.

$: << File.expand_path("../../../lib", __FILE__)
require 'asir_transport_http'

require 'math_service'
MathService.send(:include, ASIR::Client)

port = 3001
begin
  t = ASIR::Transport::HTTP.new(:uri => "http://localhost:#{port}/")
  t._log_enabled = true
  t.logger = $stderr
  c = t.encoder = ASIR::Coder::Marshal.new
  c._log_enabled = true
  c.logger = $stderr

  server_pid = Process.fork do
    t.setup_server!
    t.start_server!
  end

  MathService.client.transport = t
  MathService.client.sum([1, 2, 3])
rescue Exception => err
  $stderr.puts "ERROR: #{err.inspect}\n#{err.backtrace * "\n"}"
ensure
  Process.kill(9, server_pid)
end



