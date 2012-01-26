# !SLIDE :capture_code_output true
# Replay file log

require 'example_helper'
begin
  service_log = "#{__FILE__.sub('ex05', 'ex04')}.service.log"
  Email.client.transport = t =
    ASIR::Transport::File.new(:file => service_log)
  t.encoder = 
    ASIR::Coder::Yaml.new

  t.serve_file!
end

# !SLIDE END
# EXPECT: : client process
# EXPECT: : Email.send_mail :pdf_invoice
