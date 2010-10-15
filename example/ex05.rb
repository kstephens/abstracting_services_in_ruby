# !SLIDE :capture_code_output true
# Replay file log

require 'example_helper'
begin
  service_log = "service.log"
  Email.client.transport = 
    ASIR::Transport::File.new(:file => service_log)
  Email.client.transport.encoder = 
    ASIR::Coder::Yaml.new

  Email.client.transport.service_file!
ensure
  File.unlink(service_log) rescue nil
end

