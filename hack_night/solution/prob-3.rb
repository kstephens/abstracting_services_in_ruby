# Call the MathService using the ASIR::Transport::Subprocess mixin.

$: << File.expand_path("../../../lib", __FILE__)
require 'asir'
require 'asir/transport/subprocess'

require 'math_service'
MathService.send(:include, ASIR::Client)

######################################################################
# Driver:

begin
  MathService.client.transport = ASIR::Transport::Subprocess.new
  MathService.client.transport._log_enabled = true
  puts MathService.client.sum([1, 2, 3])
end
