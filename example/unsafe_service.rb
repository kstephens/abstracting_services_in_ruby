require 'asir'

module UnsafeService
  include ASIR::Client
  def self.do_it(expr)
    result = eval(expr)
    puts "#{$$}: UnsafeService.do_it(#{expr}) #{result.inspect}"
    $stderr.puts "#{$$}: UnsafeService.do_it => #{result.inspect}"
    result
  end
end

