#
# !SLIDE :capture_code_output true
# One-way, asynchronous subprocess service

require 'example_helper'
begin
  Email.asir.transport = t =
    ASIR::Transport::Subprocess.new

  pr Email.asir.send_email(:pdf_invoice,
                             :to => "user@email.com",
                             :customer => @customer)
end

# !SLIDE END
# EXPECT: : client process
# EXPECT: : Email.send_mail :pdf_invoice
# EXPECT: : pr: nil

