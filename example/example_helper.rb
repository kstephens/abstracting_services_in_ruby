# Sample client support
#

require 'pp'

$_log_verbose = true
@customer = 123
def pr result
  puts "*** #{$$}: pr: #{PP.pp(result, '')}"
end

require 'asir'
require 'sample_service'

