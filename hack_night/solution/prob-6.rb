# Write a ASIR::Transport::HTTP class that uses HTTP::Client for transport send_result and receive_result.
# And WEBrick to handle requests.

$: << File.expand_path("../../../lib", __FILE__)
require 'asir/transport/webrick'
require 'asir/coder/marshal'

require 'math_service'
MathService.send(:include, ASIR::Client)

Process.exit!(0) if RUBY_PLATFORM =~ /java/i

port = 3001
begin
  t = ASIR::Transport::Webrick.new(:uri => "http://localhost:#{port}/")
  t._log_enabled = true
  c = t.encoder = ASIR::Coder::Marshal.new
  c._log_enabled = true

  server_pid = Process.fork do
    t.prepare_server!
    t.run_server!
  end
  sleep 1 # wait for server to start

  MathService.asir.transport = t
  MathService.asir.sum([1, 2, 3])

rescue Exception => err
  $stderr.puts "ERROR: #{err.inspect}\n#{err.backtrace * "\n"}"

ensure
  sleep 1
  Process.kill(9, server_pid)
end

