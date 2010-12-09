
module MathService
  def sum array_of_numbers
    raise TypeError unless Array === array_of_numbers
    array_of_numbers.inject(0) do | s, e |
      raise TypeError unless Numeric === e
      s += e
    end
  end
  extend self
end
