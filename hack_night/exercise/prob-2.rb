# Call the MathService using the ASIR::Client mixin.
# Assume the default Transport and Coder.

$: << File.expand_path("../../../lib", __FILE__)
require 'asir'

module MathService
  # ???
  def sum array_of_numbers
    # ???
    return -123
  end
  extend self
end

######################################################################
# Driver:

begin
  puts MathService # ???  # => 6
end

