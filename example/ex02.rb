# !SLIDE :capture_code_output true
# In-core, in-process service

require 'example_helper'
pr Email.client.send_email(:pdf_invoice,
                           :to => "user@email.com",
                           :customer => @customer)

