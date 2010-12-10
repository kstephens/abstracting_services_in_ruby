# Sample client support
#

require 'pp'

@customer = 123
def pr result
  puts "*** #{$$}: pr: #{PP.pp(result, '')}"
end

$: << File.expand_path("../../lib", __FILE__)
require 'asir'
ASIR::Log.enabled = true
require 'sample_service'

