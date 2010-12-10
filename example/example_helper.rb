# Sample client support
#

require 'pp'

@customer = 123
def pr result
  puts "*** #{$$}: pr: #{PP.pp(result, '')}"
end

$: << File.expand_path("../../lib", __FILE__)
require 'asir'
require 'asir/transport/tcp_socket'
require 'asir/coder/marshal'
require 'asir/coder/yaml'
require 'asir/coder/sign'
ASIR::Log.enabled = true
require 'sample_service'

