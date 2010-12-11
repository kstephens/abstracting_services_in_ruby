# Sample client support
#

require 'pp'

@customer = 123
puts "*** #{$$}: client process"; $stdout.flush
def pr result
  puts "*** #{$$}: pr: #{PP.pp(result, '')}"
end

$: << File.expand_path("../../lib", __FILE__)
require 'asir'
require 'asir/transport/tcp_socket'
require 'asir/coder/marshal'
require 'asir/coder/yaml'
require 'asir/coder/sign'
require 'asir/coder/chain'
ASIR::Log.enabled = true unless ENV['ASIR_EXAMPLE_SILENT']
require 'sample_service'

