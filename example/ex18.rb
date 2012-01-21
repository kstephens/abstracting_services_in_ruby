# !SLIDE :capture_code_output true
# Socket service with retry.

require 'example_helper'
require 'asir/transport/retry'
begin
  File.unlink(service_log = "service.log") rescue nil

  file = ASIR::Transport::File.new(:file => service_log,
                                   :encoder => ASIR::Coder::Yaml.new)

  tcp = ASIR::Transport::TcpSocket.new(:port => 31918,
                                       :encoder => ASIR::Coder::Marshal.new)

  start_server_proc = lambda do | transport, request |
    $stderr.puts "request = #{request.inspect}"
    file.send_request(request)
    server_process do
      tcp.prepare_socket_server!
      tcp.run_socket_server!
    end; sleep 2
  end

  Email.client.transport = t =
    ASIR::Transport::Retry.new(:transport => tcp,
                               :try_sleep => 1,
                               :try_sleep_increment => 2,
                               :try_max => 3,
                               :before_retry => start_server_proc
                               )

  pr Email.client.send_email(:pdf_invoice, 
                             :to => "user@email.com", :customer => 123)
  sleep 1

  pr Email.client.send_email(:pdf_invoice, 
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
# EXPECT: "service.log" contents:
# EXPECT: --- !ruby/object:ASIR::Request 
# EXPECT:   :transport_exceptions:
# EXPECT: ASIR::Error: Cannot connect to 127.0.0.1:
# EXPECT: arguments: 
# EXPECT: - :pdf_invoice
# EXPECT/:  :to: user@email.com
# EXPECT/:  :customer: 123
# EXPECT!/:  :to: user2@email.com
# EXPECT!/:  :customer: 456
# EXPECT: receiver: Email
# EXPECT: receiver_class: Module
# EXPECT: selector: :send_email
