# !SLIDE :capture_code_output true
# In-core, in-process service, with continuation block.

require 'example_helper'
pr(Email.client.send_email(:pdf_invoice,
                           :to => "user@email.com",
                           :customer => @customer,
                           &proc { | response | pr [ :in_block, response.result ] })
)

# !SLIDE END
# EXPECT: : client process
# EXPECT: : Email.send_mail :pdf_invoice
# EXPECT: : pr: :ok
# EXPECT: : pr: [:in_block, :ok]
