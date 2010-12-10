# prob-1.rb
# Write a MathService module that has a method that can sum an Array of Numbers
# It should raise an exception if not given an Array.
# It should raise an exception if any elements are not Numeric.

module MathService
  def sum array_of_numbers
    # ???
  end
  extend self
end

######################################################################

begin
  puts MathService.sum([1, 2, 3]) # => 6
end

