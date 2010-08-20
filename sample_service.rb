=begin
# !SLIDE
# Sample Service
#
module SomeService
  def do_it x, y
    x * y + 42
  end

  def do_raise msg
    raise msg
  end

  extend self
end

SomeService.do_it(1, 2)
# !SLIDE END
=end

# !SLIDE
# Example Request
#
# @@@ ruby
#   SomeService.do_it(1, 2)
# @@@
#
#   =>
# @@@ ruby  
#   request = Request.new(...)
#   request.reciever_class = Module
#   request.reciever = "SomeService"
#   request.selector = :do_it
#   request.arguments = [ 1, 2 ]
# @@@
#
# !SLIDE END

# !SLIDE
# Example Exception
#
# @@@ ruby
#   SomeService.do_raise("DOH!")
# @@@
#
#   =>
#
# @@@ ruby  
#   response.exception = ee = EncapsulatedException.new(...)
#   ee.exception_class = '::RuntimeError"
#   ee.exception_message = 'DOH!"
#   ee.execption_backtrace = [ ... ]
# @@@
#
# !SLIDE END

# !SLIDE
# Sample Service with Client Support
# 

require 'asir'

# Added logging and #client support.
module SomeService
  include SI::Client # SomeService.client
  include SI::Log    # SomeService#_log_result

  def do_it x, y
    _log_result [ :do_it, x, y ] do 
      x * y + 42
    end
  end

  def do_raise msg
    raise msg
  end

  extend self
end
# !SLIDE END

