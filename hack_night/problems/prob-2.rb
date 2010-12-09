# Write a Coder that can encode an Array of Numbers as a String and decode a String into a Number.
# Hint: inspect .vs. eval

$: << File.expand_path("../../../lib", __FILE__)
require 'asir'

module ASIR
  class Coder
    class Simple < self
      def _encode obj
        # ???
        obj
      end
      def _decode obj
        raise TypeError unless String === obj
        # ???
        obj
      end
    end
  end
end

######################################################################

begin
  input = [ 1, 2, 3 ]
  puts "input  = #{input.inspect}"
  coder = ASIR::Coder::Simple.new
  coder._log_enabled = true
  coder.logger = $stderr
  output = coder.encode(input)
  puts "output = #{output.inspect}"
  result = coder.decode(output)
  puts "result = #{result.inspect}"
end

