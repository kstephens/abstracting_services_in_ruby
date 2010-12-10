# Write a Base64 Coder

$: << File.expand_path("../../../lib", __FILE__)
require 'asir_coder_base64'

######################################################################

begin
  input = "abc123"
  puts "input  = #{input.inspect}"

  coder = ASIR::Coder::Base64.new
  coder._log_enabled = true

  output = coder.encode(input)
  puts "output = #{output.inspect}"

  result = coder.decode(output)
  puts "result = #{result.inspect}"
end

