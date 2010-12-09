# Call the MathService using the ASIR::Client mixin.

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
  puts MathService.sum([1, 2, 3]) # => 6
end

