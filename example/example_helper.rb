# Sample client support
#

$: << File.expand_path("../../lib", __FILE__)
require 'asir'
require 'asir/transport/file'
require 'asir/transport/local'
require 'asir/transport/subprocess'
require 'asir/transport/tcp_socket'
require 'asir/transport/fallback'
require 'asir/transport/broadcast'
require 'asir/coder/marshal'
require 'asir/coder/yaml'
require 'asir/coder/sign'
require 'asir/coder/chain'
ASIR::Log.enabled = true unless ENV['ASIR_EXAMPLE_SILENT']
require 'sample_service'
require 'delayed_service'
require 'unsafe_service'

require 'pp'

require 'rubygems'
gem 'ruby-debug'
require 'ruby-debug'

@customer = 123

class ::Object

def pr result
  $stdout.puts "*** #{$$}: pr: #{PP.pp(result, '')}"
end

def server_process &blk
  $server_pid = Process.fork do
    puts "*** #{$$}: server process"; $stdout.flush
    yield
  end
  sleep 1 # wait for server to be ready.
end

def server_kill
  if $server_pid
    Process.kill 9, $server_pid
    Process.waitpid($server_pid)
  end
  $server_pid = nil
end

end

puts "*** #{$$}: client process"; $stdout.flush

