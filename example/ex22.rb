# !SLIDE :capture_code_output true
# In-core, in-process service, with continuation block.

require 'example_helper'
pr(Email.asir.send_email(:pdf_invoice,
                           :to => "user@email.com",
                           :customer => @customer,
                           &proc { | res | pr [ :in_block, res.result ] })
)

# !SLIDE END
# EXPECT: : client process
# EXPECT: : Email.send_mail :pdf_invoice
# EXPECT: : pr: :ok
# EXPECT: : pr: [:in_block, :ok]
