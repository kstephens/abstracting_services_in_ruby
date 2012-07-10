# Sample client support
#
require 'rubygems'
case RUBY_PLATFORM
when /java/i
  gem 'spoon'; require 'spoon'
end

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
require File.expand_path('../../spec/debug_helper', __FILE__)

@customer = 123

class ::Object

def pr result
  $stdout.puts "*** #{$$}: pr: #{PP.pp(result, '')}"
end

def server_process &blk
  # $stderr.puts "  at #{__FILE__}:#{__LINE__}"
  case RUBY_PLATFORM
  when /java/i
    # JRuby cannot fork.
    # So we must prevent spawn a new jruby and
    # instruct it to only run the server blk, and not
    # the subsequent client code.
    # In other words, we cannot rely on how Process.fork
    # terminates within the block.
    if ENV['ASIR_JRUBY_SPAWNED']
      $stderr.puts "  spawned server at #{__FILE__}:#{__LINE__}"
      puts "*** #{$$}: server process"; $stdout.flush
      yield
      Process.exit!(0)
      # dont do client, client is our parent process.
    else
      $stderr.puts "  spawning at #{__FILE__}:#{__LINE__}"
      ENV['ASIR_JRUBY_SPAWNED'] = "1"
      cmd = "ruby -I #{File.dirname(__FILE__)} -I #{File.expand_path('../../lib', __FILE__)} #{$0} #{ARGV * ' '}"
      $stderr.puts "  cmd = #{cmd}"
      $server_pid = Spoon.spawnp(cmd)
      ENV.delete('ASIR_JRUBY_SPAWNED')
      $stderr.puts "  spawned #{$server_pid} at #{__FILE__}:#{__LINE__}"
    end
  else
    # $stderr.puts "  at #{__FILE__}:#{__LINE__}"
    $server_pid = Process.fork do
      puts "*** #{$$}: server process"; $stdout.flush
      yield
    end
  end
  sleep 1 # wait for server to be ready.
  return false # do client.
end

def server_kill
  if $server_pid
    Process.kill 9, $server_pid
    Process.waitpid($server_pid)
  end
rescue Errno::ESRCH
ensure
  $server_pid = nil
end

end

puts "*** #{$$}: client process"; $stdout.flush

