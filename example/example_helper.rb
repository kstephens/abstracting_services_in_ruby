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
require 'asir/transport/thread'
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
require 'timeout'
require File.expand_path('../../spec/debug_helper', __FILE__)

@customer = 123

class ::Object

def pr result
  $stdout.puts "*** #{$$}: pr: #{PP.pp(result, '')}"
end

# Work-around lack of fork in JRuby.
require 'asir/application'
$asir_app = ASIR::Application.new
$asir_app.inc = [ 'example', 'lib' ]
$asir_server = nil

def server_process &blk
  $asir_server = $asir_app.spawn :server do
    puts "*** #{$$}: server process"; $stdout.flush
    begin
      Timeout.timeout(20, ASIR::Error::Fatal) do
        yield
      end
    rescue ::Exception => exc
      $stderr.puts "*** #{$$}: service ERROR: #{exc.inspect}\n  #{exc.backtrace * "  \n"}"
      raise exc
    end
  end
  $asir_app.main do
    $asir_server.go!
    $server_pid = $asir_server.pid
    sleep 1 # wait for server to be ready.
  end
  return false # do client.
end

def server_kill
  if $server_pid
    $asir_server.kill
  end
ensure
  $server_pid = nil
end

end # class Object

module Process
  include ASIR::Client
end

unless $asir_app.in_spawn?
  puts "*** #{$$}: client process"; $stdout.flush
end

