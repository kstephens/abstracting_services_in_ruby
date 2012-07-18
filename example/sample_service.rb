=begin
# !SLIDE
# Stuff Gets Complicated
#
# Systems become:
# * bigger ->
# * complex ->
# * slower ->
# * distributed ->
# * hard to test
#
# !SLIDE END

# !SLIDE
# Sample Service
#
module Email
  def send_email template_name, options
    $stderr.puts "*** #{$$}: Email.send_mail #{template_name.inspect} #{options.inspect}"
    :ok
  end
  def do_raise msg
    raise msg
  end
  extend self
end
# !SLIDE END

# !SLIDE
# Back when things were simple...
#
class CustomersController < ApplicationController
  def send_invoice
    @customer = Customer.find(params[:id])
    Email.send_email(:pdf_invoice,
                     :to => @customer.email,
                     :customer => @customer)
  end
end
# !SLIDE END

# !SLIDE
# Trying to improve user's experience...
#
class CustomersController < ApplicationController
  def send_invoice
    @customer = Customer.find(params[:id])
    Process.fork do
      Email.send_email(:pdf_invoice,
                       :to = @customer.email,
                       :customer => @customer)
    end
  end
end
# !SLIDE END

# !SLIDE
# Use other machines to poll a work table...
#
class CustomersController < ApplicationController
  def send_invoice
    @customer = Customer.find(params[:id])
    EmailWork.create(:template_name => :pdf_invoice,
                     :options => {
                       :to => @customer.email,
                       :customer => @customer,
                     })
  end
end
# !SLIDE END

# !SLIDE
# Use queue infrastructure
#
class CustomersController < ApplicationController
  def send_invoice
    @customer = Customer.find(params[:id])
    queue_service.put(:queue => :Email,
                      :action => :send_email,
                      :template_name => :pdf_invoice,
                      :options => {
                        :to => @customer.email,
                        :customer => @customer,
                      })
  end
end
# !SLIDE END

# !SLIDE
# Example Message
#
Email.asir.send_email(:pdf_invoice,
                        :to => "user@email.com",
                        :customer => @customer)
# ->
message = Message.new(...)
message.receiver_class == ::Module
message.receiver == ::Email
message.selector == :send_email
message.arguments == [ :pdf_invoice,
                       { :to => "user@email.com",
                         :customer => ... } ]
# !SLIDE END

# !SLIDE
# Using a Client Proxy
#
Email.send_email(:pdf_invoice,
                 :to => "user@email.com",
                 :customer => @customer)
# ->
Email.asir.
      send_email(:pdf_invoice,
                 :to => "user@email.com",
                 :customer => @customer)
# !SLIDE END

# !SLIDE
# Example Exception
#
Email.do_raise("DOH!")
#
# ->
result.exception = ee = EncapsulatedException.new(...)
ee.exception_class = "::RuntimeError"
ee.exception_message = "DOH!"
ee.exception_backtrace = [ ... ]
# !SLIDE END
=end

# !SLIDE
# Sample Service with Client Support
#

require 'asir'
# Added .asir support.
module Email
  include ASIR::Client # Email.asir
  def send_email template_name, options
    $stderr.puts "*** #{$$}: Email.send_mail #{template_name.inspect} #{options.inspect}"
    :ok
  end
  def do_raise msg
    raise msg
  end
  extend self
end
# !SLIDE END

# !SLIDE
# Sample Object Instance Client
#
class MyClass
  include ASIR::Client
  def initialize x
    @x = x
  end
  def method_missing sel, *args
    @x.send(sel, *args)
  end
end
# !SLIDE END
