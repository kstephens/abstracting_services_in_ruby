# !SLIDE :capture_code_output true
# Socket service with local fallback.

require 'example_helper'
begin
  File.unlink(service_log = "service.log") rescue nil

  Email.client.transport = t =
    ASIR::Transport::Fallback.new(:transports => [
      tcp = ASIR::Transport::TcpSocket.new(:port => 30903,
                                           :encoder => ASIR::Coder::Marshal.new),
      ASIR::Transport::Broadcast.new(:transports => [ 
        file = ASIR::Transport::File.new(:file => service_log,
                                         :encoder => ASIR::Coder::Yaml.new),
        ASIR::Transport::Subprocess.new,
      ]),
    ])

  pr Email.client.send_email(:pdf_invoice, 
                             :to => "user@email.com", :customer => @customer)

  tcp.prepare_socket_server!
  server_process do
    tcp.run_socket_server!
  end

  pr Email.client.send_email(:pdf_invoice, 
                             :to => "user2@email.com", :customer => @customer)
  
ensure
  file.close;
  tcp.close; sleep 1
  server_kill
  puts "\x1a\n#{service_log.inspect} contents:"
  puts File.read(service_log)
end

# !SLIDE END
# EXPECT: : client process
# EXPECT: : server process
# EXPECT: : Email.send_mail :pdf_invoice {:to=>"user@email.com", :customer=>123}
# EXPECT: : Email.send_mail :pdf_invoice {:to=>"user2@email.com", :customer=>123}
# EXPECT: : pr: :ok
# EXPECT: "service.log" contents:
# EXPECT: 159
# EXPECT: --- !ruby/object:ASIR::Request 
# EXPECT: arguments: 
# EXPECT: - :pdf_invoice
# EXPECT: - :to: user@email.com
# EXPECT:   :customer: 123
# EXPECT: receiver: Email
# EXPECT: receiver_class: Module
# EXPECT: selector: :send_email
