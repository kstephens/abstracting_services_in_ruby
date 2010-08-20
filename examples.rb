=begin
# !SLIDE :index 100
# Sample Service
#
module SomeService
  def do_it x, y
    x * y + 42
  end
  def do_raise msg
    raise msg
  end
  extend self
end

SomeService.do_it(1, 2)
# !SLIDE END
=end


# !SLIDE :index 102 :capture_code_output true
# Call service directly

require 'demo_helper'
pr SomeService.do_it(1, 2)

# !SLIDE :index 301 :capture_code_output true
# In-core, in-process service

require 'demo_helper'
pr SomeService.client.do_it(1, 2)

# !SLIDE :index 401 :capture_code_output true
# One-way, asynchronous subprocess service

require 'demo_helper'
begin
SomeService.client.transport = SI::Transport::Subprocess.new

pr SomeService.client.do_it(1, 2)
end

# !SLIDE :index 501 :capture_code_output true
# One-way, file log service

require 'demo_helper'
begin
File.unlink(service_log = "service.log") rescue nil
SomeService.client.transport = SI::Transport::File.new(:file => service_log)
SomeService.client.transport.encoder = SI::Coder::Yaml.new

pr SomeService.client.do_it(1, 2)

ensure
SomeService.client.transport.close

puts "#{service_log.inspect} contents:"
puts File.read(service_log)
end

# !SLIDE :index 550 :capture_code_output true
# Replay file log

require 'demo_helper'
begin
service_log = "service.log"
SomeService.client.transport = SI::Transport::File.new(:file => service_log)
SomeService.client.transport.encoder = SI::Coder::Yaml.new

SomeService.client.transport.service_file!

ensure
File.unlink(service_log) rescue nil
end

# !SLIDE :index 601 :capture_code_output true
# One-way, named pipe service

require 'demo_helper'
begin
File.unlink(service_fifo = "service.fifo") rescue nil
SomeService.client.transport = SI::Transport::File.new(:file => service_fifo)
SomeService.client.transport.encoder = SI::Coder::Yaml.new

SomeService.client.transport.prepare_fifo_server!
child_pid = Process.fork do 
  SomeService.client.transport.run_fifo_server!
end

pr SomeService.client.do_it(1, 2)

ensure
SomeService.client.transport.close
sleep 2
Process.kill 9, child_pid
File.unlink(service_fifo) rescue nil
end

# !SLIDE :index 701 :capture_code_output true
# One-way, named pipe service with signature

require 'demo_helper'
begin
File.unlink(service_fifo = "service.fifo") rescue nil
SomeService.client.transport = SI::Transport::File.new(:file => service_fifo)
SomeService.client.transport.encoder = 
  SI::Coder::Multi.new(:encoders =>
                         [ SI::Coder::Marshal.new,
                           SI::Coder::Sign.new(:secret => 'abc123'),
                           SI::Coder::Yaml.new,
                         ])

SomeService.client.transport.prepare_fifo_server!
child_pid = Process.fork do 
  SomeService.client.transport.run_fifo_server!
end

pr SomeService.client.do_it(1, 2)

ensure
SomeService.client.transport.close
sleep 2
Process.kill 9, child_pid
end


# !SLIDE :index 801 :capture_code_output true
# One-way, named pipe service with invalid signature

require 'demo_helper'
begin
File.unlink(service_fifo = "service.fifo") rescue nil
SomeService.client.transport = SI::Transport::File.new(:file => service_fifo)
SomeService.client.transport.encoder = 
  SI::Coder::Multi.new(:encoders =>
                         [ SI::Coder::Marshal.new,
                           SI::Coder::Sign.new(:secret => 'abc123'),
                           SI::Coder::Yaml.new,
                         ])

SomeService.client.transport.prepare_fifo_server!
child_pid = Process.fork do 
  SomeService.client.transport.run_fifo_server!
end

SomeService.client.transport.encoder.encoders[1].secret = 'I dont know the secret! :('

pr SomeService.client.do_it(1, 2)

ensure
SomeService.client.transport.close
sleep 2
Process.kill 9, child_pid
end


# !SLIDE :index 901 :capture_code_output true
# Socket service

require 'demo_helper'
begin
SomeService.client.transport = SI::Transport::TcpSocket.new(:port => 50901)
SomeService.client.transport.encoder = 
    SI::Coder::Marshal.new

SomeService.client.transport.prepare_socket_server!
child_pid = Process.fork do 
  SomeService.client.transport.run_socket_server!
end

pr SomeService.client.do_it(1, 2)

ensure
SomeService.client.transport.close
sleep 2
Process.kill 9, child_pid
end

# !SLIDE :index 1001 :capture_code_output true
# Socket service with forwarded exception.

require 'demo_helper'
begin
SomeService.client.transport = SI::Transport::TcpSocket.new(:port => 51001)
SomeService.client.transport.encoder = 
    SI::Coder::Marshal.new

SomeService.client.transport.prepare_socket_server!
child_pid = Process.fork do 
  SomeService.client.transport.run_socket_server!
end

pr SomeService.client.do_raise("Raise Me!")

rescue Exception => err
  pr [ :exception, err ]
ensure
SomeService.client.transport.close
sleep 2
Process.kill 9, child_pid
end


# !SLIDE END

######################################################################


