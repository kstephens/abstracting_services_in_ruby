# !SLIDE :capture_code_output true
# Socket service with local fallback.

require 'example_helper'
begin
  File.unlink(service_log = "service.log") rescue nil

  Email.client.transport = t =
    ASIR::Transport::Fallback.new(:transports => [
      tcp = ASIR::Transport::TcpSocket.new(:port => 30903),
      ASIR::Transport::Multi.new(:transports => [ 
        file = ASIR::Transport::File.new(:file => service_log,
                                         :encoder => ASIR::Coder::Yaml.new),
        ASIR::Transport::Subprocess.new,
      ]),
    ])
  tcp.encoder = 
    ASIR::Coder::Marshal.new

  pr Email.client.send_email(:pdf_invoice, 
                             :to => "user@email.com", :customer => @customer)

  tcp.prepare_socket_server!
  child_pid = Process.fork do 
    tcp.run_socket_server!
  end

  pr Email.client.send_email(:pdf_invoice, 
                             :to => "user2@email.com", :customer => @customer)
  
ensure
  file.close;
  tcp.close; sleep 1
  Process.kill 9, child_pid
  puts "\x1a\n#{service_log.inspect} contents:"
  puts File.read(service_log)
end
