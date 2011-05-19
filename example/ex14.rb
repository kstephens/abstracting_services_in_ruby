# !SLIDE :capture_code_output true
# Synchronous HTTP service on instance methods.

require 'example_helper'
require 'asir/transport/http'
require 'asir/coder/base64'

begin
  class MyClass
    include ASIR::Client
    def initialize x
      @x = x
    end
    def method_missing sel, *args
      @x.send(sel, *args)
    end
  end

  MyClass.client.transport = t = 
    ASIR::Transport::HTTP.new(:uri => "http://localhost:30914/")
  t.encoder =
    ASIR::Coder::Chain.new(:encoders => 
                           [
                            ASIR::Coder::Marshal.new,
                            ASIR::Coder::Base64.new,
                           ])
  
  server_process do
    t.setup_webrick_server!
    t.start_webrick_server!
  end; sleep 2

  pr MyClass.new("abc123").client.size

  sleep 2
  
rescue Object => err
  $stderr.puts "#{err.inspect}\n#{err.backtrace * "\n"}"
ensure
  t.close; sleep 3
  server_kill; sleep 2
end

# !SLIDE END
# EXPECT: : client process
# EXPECT: : server process
# EXPECT: : pr: 6

