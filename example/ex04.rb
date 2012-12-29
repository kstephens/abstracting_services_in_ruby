# !SLIDE :capture_code_output true
# One-way, file log service

require 'example_helper'
begin
  File.unlink(service_log = "#{__FILE__}.service.log") rescue nil
  Email.asir.transport = t =
    ASIR::Transport::File.new(:file => service_log)
  t.encoder =
    ASIR::Coder::Yaml.new(:yaml_options => { :ASCII_8BIT_ok => true })
  pr Email.asir.send_email(:pdf_invoice,
                             :to => "user@email.com",
                             :customer => @customer)
ensure
  t.close
  puts "\x1a\n#{service_log.inspect} contents:"
  puts File.read(service_log)
end

# !SLIDE END
# EXPECT: : client process
# EXPECT: service.log" contents:
# EXPECT: pr: nil
# EXPECT: --- !ruby/object:ASIR::Message
# EXPECT: --- !ruby/object:ASIR::Message
# EXPECT: arguments:
# EXPECT: - :pdf_invoice
# EXPECT:   :to: user@email.com
# EXPECT:   :customer: 123
# EXPECT: receiver: Email
# EXPECT: receiver_class: Module
# EXPECT: selector: :send_email

