# Used by asir/bin/asir.
# Configures asir worker transport and error logging.
# asir object is bound to ASIR::Main instance.

$stderr.puts "asir.verb = #{asir.verb.inspect}"
case asir.verb
when :config
  # NOTHING
  true
when :environment
  require 'asir'
  require 'asir/transport/file'
  require 'asir/coder/marshal'
  require 'asir/coder/yaml'

  $:.unshift File.expand_path('..')
  require 'example_helper'
  require 'sample_service'
  require 'unsafe_service'
when :transport
  # Compose with Marshal for final coding.
  coder = ASIR::Coder::Marshal.new

  # Logger for worker-side Exceptions.
  error_log_file = asir.log_file.sub(/\.log$/, '-error.log')
  error_transport =
    ASIR::Transport::File.new(:file => error_log_file,
                              :mode => 'a+',
                              :perms => 0666)
  error_transport.encoder = ASIR::Coder::Yaml.new

  # Setup requested Transport.
  case asir.adjective
  when :beanstalk
    transport = ASIR::Transport::Beanstalk.new
    transport[:worker_processes] = 3
  when :http, :webrick
    transport = ASIR::Transport::Webrick.new
    transport.uri = "http://localhost:#{30000 + asir.identifier.to_s.to_i}/asir"
  when :zmq
    transport = ASIR::Transport::Zmq.new
    transport.one_way = true
    transport.uri = "tcp://localhost:#{31000 + asir.identifier.to_s.to_i}" # /asir"
  else
    raise "Cannot configure Transport for #{asir.adjective}"
  end

  transport.encoder = coder
  transport._logger = STDERR
  transport._log_enabled = true
  transport.verbose = 3
  transport.on_exception =
    lambda { | transport, exc, phase, message, *rest |
      error_transport.send_request(message)
    }

  transport
else
  $stderr.puts "Warning: unhandled asir.verb: #{asir.verb.inspect}"
end
