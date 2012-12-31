# Call the MathService using the ASIR::Transport::Subprocess mixin.

$: << File.expand_path("../../../lib", __FILE__)
require 'asir'
require 'asir/transport/subprocess'

require 'math_service'
MathService.send(:include, ASIR::Client)

Process.exit!(0) if RUBY_PLATFORM =~ /java/i

######################################################################
# Driver:

begin
  MathService.asir.transport = ASIR::Transport::Subprocess.new
  MathService.asir.transport._log_enabled = true
  puts MathService.asir.sum([1, 2, 3])
end
