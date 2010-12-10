# !SLIDE :capture_code_output true
# Replay file log

require 'example_helper'
begin
  service_log = "service.log"
  Email.client.transport = t =
    ASIR::Transport::File.new(:file => service_log)
  t.encoder = 
    ASIR::Coder::Yaml.new

  t.serve_file!
ensure
  File.unlink(service_log) rescue nil
end

# !SLIDE END
# EXPECT: : client process
# EXPECT: : Email.send_mail :pdf_invoice
