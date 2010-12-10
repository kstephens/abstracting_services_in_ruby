# Write a Base64 Coder

# require ???

$: << File.expand_path("../../../lib", __FILE__)
require 'asir'

module ASIR
  class Coder
    class Base64 < self
      def _encode obj
        raise TypeError unless String === obj
        # ???
      end

      def _decode obj
        raise TypeError unless String === obj
        # ???
      end
    end
  end
end

######################################################################

begin
  input = "abc123"
  puts "input  = #{input.inspect}"
  coder = ASIR::Coder::Base64.new
  coder._log_enabled = true
  coder.logger = $stderr
  output = coder.encode(input)
  puts "output = #{output.inspect}"
  result = coder.decode(output)
  puts "result = #{result.inspect}"
end
