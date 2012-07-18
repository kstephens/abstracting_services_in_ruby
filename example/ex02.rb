# !SLIDE :capture_code_output true
# In-core, in-process service

require 'example_helper'
pr Email.asir.send_email(:pdf_invoice,
                           :to => "user@email.com",
                           :customer => @customer)

# !SLIDE END
# EXPECT: : client process
# EXPECT: : Email.send_mail :pdf_invoice
# EXPECT: : pr: :ok
