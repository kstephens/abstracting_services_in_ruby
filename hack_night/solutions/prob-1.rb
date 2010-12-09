# Write a MathService module that has a method that can sum an Array of Numbers
# It should raise an exception if not given an Array.
# It should raise an exception if any elements are not Numeric.

require 'math_service'

######################################################################

begin
  puts MathService.sum([1, 2, 3]) # => 6
end

