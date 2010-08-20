# Sample client support
#

require 'pp'

$_log_verbose = true
def pr result
  puts PP.pp([ :result, result ], '')
end

require 'asir'
require 'sample_service'

