# !SLIDE :capture_code_output true
# Call service directly

require 'example_helper'
pr Email.send_email(:pdf_invoice, 
                    :to => "user@email.com",
                    :customer => @customer)

# !SLIDE END
# EXPECT: : client process
# EXPECT: : Email.send_mail :pdf_invoice
# EXPECT: : pr: :ok
