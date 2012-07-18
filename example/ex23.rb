#
# !SLIDE :capture_code_output true
# Subprocess service with continuation

require 'example_helper'
begin
  Email.asir.transport = t =
    ASIR::Transport::Subprocess.new(:one_way => true)
  pr(Email.asir.send_email(:pdf_invoice,
                             :to => "user@email.com",
                             :customer => @customer) { | resp |
     pr [ :in_block, resp.result ] })
end

# !SLIDE END
# EXPECT: : client process
# EXPECT: : Email.send_mail :pdf_invoice
# EXPECT: : pr: nil
# EXPECT: : pr: [:in_block, :ok]

