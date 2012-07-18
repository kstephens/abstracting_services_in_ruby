# !SLIDE :capture_code_output true
# Socket service with unsafe Exception.

require 'example_helper'
begin
  tcp = ASIR::Transport::TcpSocket.new(:port => 31919,
                                       :encoder => ASIR::Coder::Marshal.new)
  server_process do
    tcp.prepare_server!
    tcp.run_server!
  end
  UnsafeService.asir.transport = t = tcp
  pr UnsafeService.asir.do_it("exit 999; :ok")
  sleep 1
rescue ::ASIR::Error::Unforwardable => err
  $stderr.puts "### #{$$}: Unforwardable ERROR: #{err.inspect}}"
rescue ::Exception => err
  $stderr.puts "### #{$$}: ERROR: #{err.inspect}\n  #{err.backtrace * "\n  "}"
  raise
ensure
  file.close rescue nil;
  tcp.close rescue nil; sleep 1
  server_kill
#  puts "\x1a\n#{service_log.inspect} contents:"
#  puts File.read(service_log)
end

# !SLIDE END
# EXPECT: : client process
# EXPECT: : server process
# EXPECT!: : pr: :ok
# EXPECT: Unforwardable ERROR: #<ASIR::Error::Unforwardable: SystemExit
