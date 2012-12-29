# !SLIDE :capture_code_output true
# Socket service with retry.

require 'example_helper'
require 'asir/transport/retry'
begin
  File.unlink(service_log = "#{__FILE__}.service.log") rescue nil
  file = ASIR::Transport::File.new(:file => service_log,
                               :encoder => ASIR::Coder::Yaml.new(:yaml_options => { :ASCII_8BIT_ok => true }))
  tcp = ASIR::Transport::TcpSocket.new(:port => 31918,
                                       :encoder => ASIR::Coder::Marshal.new)
  start_server_proc = lambda do | transport, message |
    $stderr.puts "message = #{message.inspect}"
    file.send_message(message)
    server_process do
      tcp.prepare_server!
      tcp.run_server!
    end
  end
  Email.asir.transport = t =
    ASIR::Transport::Retry.new(:transport => tcp,
                               :try_sleep => 1,
                               :try_sleep_increment => 2,
                               :try_max => 3,
                               :before_retry => start_server_proc
                               )
  pr Email.asir.send_email(:pdf_invoice,
                             :to => "user@email.com", :customer => 123)
  sleep 1
  pr Email.asir.send_email(:pdf_invoice,
                             :to => "user2@email.com", :customer => 456)
  sleep 1
rescue ::Exception => err
  $stderr.puts "ERROR: #{err.inspect}\n  #{err.backtrace * "\n  "}"
  raise
ensure
  file.close rescue nil;
  tcp.close rescue nil; sleep 1
  server_kill
  puts "\x1a\n#{service_log.inspect} contents:"
  puts File.read(service_log)
end

# !SLIDE END
# EXPECT: : client process
# EXPECT: : server process
# EXPECT/: : Email.send_mail :pdf_invoice .*:to=>"user@email.com"
# EXPECT/: : Email.send_mail :pdf_invoice .*:to=>"user2@email.com"
# EXPECT: : pr: :ok
# EXPECT: service.log" contents:
# EXPECT: --- !ruby/object:ASIR::Message
# EXPECT:   :transport_exceptions:
# EXPECT: Cannot connect to ASIR::Transport::TcpSocket tcp://127.0.0.1:
# EXPECT: arguments:
# EXPECT: - :pdf_invoice
# EXPECT/:  :to: user@email.com
# EXPECT/:  :customer: 123
# EXPECT!/:  :to: user2@email.com
# EXPECT!/:  :customer: 456
# EXPECT: receiver: Email
# EXPECT: receiver_class: Module
# EXPECT: selector: :send_email
