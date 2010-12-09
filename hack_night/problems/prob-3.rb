# Call the MathService using the ASIR::Transport::Subprocess mixin.

$: << File.expand_path("../../../lib", __FILE__)
require 'asir'

require 'math_service'
MathService.send(:include, ASIR::Client)

######################################################################
# Driver:

begin
  # MathService.client.transport = ??? 
  MathService.client.transport._log_enabled = true
  MathService.client.transport.logger = $stderr
  puts MathService.client.sum([1, 2, 3])
end
