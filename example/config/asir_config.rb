# Used by asir/bin/asir.
# Configures asir worker transport and error logging.
# asir object is bound to ASIR::Environment instance.

$stderr.puts "asir.phase = #{asir.phase.inspect}" if asir.verbose >= 1
case asir.phase
when :configure
  # NOTHING
  true
when :environment
  require 'rubygems'

  $:.unshift File.expand_path('../..', __FILE__)
  $:.unshift File.expand_path('../../../lib', __FILE__)

  require 'asir'
  require 'asir/transport/file'
  require 'asir/coder/marshal'
  require 'asir/coder/yaml'

  require 'example_helper'
  require 'sample_service'
  require 'unsafe_service'
when :start
  # NOTHING
  true
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
  when :http, :webrick
    require 'asir/transport/webrick'
    transport = ASIR::Transport::Webrick.new
    transport.uri = "http://localhost:#{30000 + asir.identifier.to_s.to_i}/asir"
  when :rack
    require 'asir/transport/rack'
    transport = ASIR::Transport::Rack.new
    transport.uri = "http://localhost:#{30000 + asir.identifier.to_s.to_i}/asir"
  else
    raise "Cannot configure Transport for #{asir.adjective}"
  end

  transport.encoder = coder
  transport._logger = STDERR
  transport._log_enabled = true
  # transport.verbose = 3
  transport.on_exception =
    lambda { | transport, exc, phase, message, result |
      error_transport.send_request(message)
    }

  transport
else
  $stderr.puts "Warning: unhandled asir.phase: #{asir.phase.inspect}"
end
