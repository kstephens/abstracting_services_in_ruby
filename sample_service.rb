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
    $stderr.puts "*** Email.send_mail #{template_name.inspect} #{options.inspect}"
  end

  def do_raise msg
    raise msg
  end

  extend self
end

Email.send_email(:giant_pdf_invoice, :to => "user@email.com", :customer => @customer)
# !SLIDE END

# !SLIDE
# Back when things were simple...
#
class CustomersController < ApplicationController
  def send_invoice
    @customer = Customer.find(params[:id])
    Email.send_email(:giant_pdf_invoice,
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
      Email.send_email(:giant_pdf_invoice,
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
    Email.create(:template_name => :giant_pdf_invoice, 
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
                      :template_name => :giant_pdf_invoice, 
                      :options => { 
                        :to => @customer.email,
                        :customer => @customer,
                      })
  end
end
# !SLIDE END
=end

# !SLIDE
# Example Request
#
# @@@ ruby
#   Email.send_email(:giant_pdf_invoice, 
#                    :to => "user@email.com",
#                    :customer => @customer)
# @@@
#
#   =>
# @@@ ruby  
#   request = Request.new(...)
#   request.reciever_class = Module
#   request.reciever = "Email"
#   request.selector = :send_email
#   request.arguments = [ :giant_pdf_invoice,
#                         { :to => "user@email.com", :customer => ... } ]
# @@@
#
# !SLIDE END

# !SLIDE
# Example Exception
#
# @@@ ruby
#   Email.do_raise("DOH!")
# @@@
#
#   =>
#
# @@@ ruby  
#   response.exception = ee = EncapsulatedException.new(...)
#   ee.exception_class = "::RuntimeError"
#   ee.exception_message = "DOH!"
#   ee.exception_backtrace = [ ... ]
# @@@
#
# !SLIDE END

# !SLIDE
# Sample Service with Client Support
# 

require 'asir'

# Added .client support.
module Email
  include SI::Client # Email.client

  def send_email template_name, options
    $stderr.puts "*** Email.send_mail #{template_name.inspect} to #{options.inspect}"
  end

  def do_raise msg
    raise msg
  end

  extend self
end
# !SLIDE END

