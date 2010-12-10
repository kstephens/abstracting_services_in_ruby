# !SLIDE :capture_code_output true
# One-way, file log service

require 'example_helper'
begin
  File.unlink(service_log = "service.log") rescue nil

  Email.client.transport = t =
    ASIR::Transport::File.new(:file => service_log)
  t.encoder = 
    ASIR::Coder::Yaml.new

  pr Email.client.send_email(:pdf_invoice,
                             :to => "user@email.com",
                             :customer => @customer)
ensure
  t.close
  puts "\x1a\n#{service_log.inspect} contents:"
  puts File.read(service_log)
end

# !SLIDE END
# EXPECT: : client process
# EXPECT: "service.log" contents:
# EXPECT: pr: nil
# EXPECT: --- !ruby/object:ASIR::Request
# EXPECT: 159
# EXPECT: --- !ruby/object:ASIR::Request 
# EXPECT: arguments: 
# EXPECT: - :pdf_invoice
# EXPECT: - :to: user@email.com
# EXPECT:   :customer: 123
# EXPECT: receiver: Email
# EXPECT: receiver_class: Module
# EXPECT: selector: :send_email

