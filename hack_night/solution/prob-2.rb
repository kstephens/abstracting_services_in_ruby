# Call the MathService using the ASIR::Client mixin.

$: << File.expand_path("../../../lib", __FILE__)
require 'asir'

require 'math_service'
MathService.send(:include, ASIR::Client)

######################################################################
# Driver:

begin
  MathService.asir.transport._log_enabled = true
  puts MathService.asir.sum([1, 2, 3])
end
