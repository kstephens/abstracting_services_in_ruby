# Write a ASIR::Transport::HTTP class.
# Using HTTP::Client for transport send_message and receive_result.
# Using WEBrick for transport on the receive_message and send_result.
# Use the Marshal Coder for the Transport.

require 'rubygems'
require 'webrick'
gem 'httpclient'
require 'httpclient'
require 'uri'

$: << File.expand_path("../../../lib", __FILE__)
require 'asir'

require 'math_service'

module ASIR
  class Transport
    class HTTP < self
      attr_accessor :uri, :server, :debug

      # Client-side: HTTPClient

      # Should HTTP put the request payload String to the uri.
      # Return the HTTPClient result Message object.
      def _send_message message, message_payload
        client = ::HTTPClient.new
        # ???
      end

      # Should extract the content from the HTTPClient::Respone
      def _receive_result httpclient_response_message
        # ???
      end

      # Server-side: WEBrick

      # Extract the body from the WEBrick request.
      def _receive_message webrick_request
        # ???
      end

      # Set the WEBrick response Content-Type.
      # Set the WEBrick response body with the result_payload String.
      def _send_result result_payload, webrick_result
        # ???
      end

      # Parse the port and path of the #uri.
      # Create a @server = WEBrick::HTTPServer on the port.
      # Mount the path with a proc that calls serve_request! with the HTTP request and response objects.
      def setup_webrick_server!
        # ???
        self
      end

      # Start the WEBbrick @server.
      def start_webrick_server!
        # ???
        self
      end
    end
  end
end


port = 3001
begin
  t = # ???
  t._log_enabled = true

  c = t.encoder = ASIR::Coder::Marshal.new
  c._log_enabled = true

  # Setup and start the WEBrick server in a child process.
  server_pid = Process.fork do
    # ???
    # ???
  end
  sleep 1 # wait for server to start

  # system("curl http://localhost:#{port}/")

  MathService.asir.transport = t

  MathService.asir.sum([1, 2, 3])

rescue Exception => err
  $stderr.puts "ERROR: #{err.inspect}\n#{err.backtrace * "\n"}"

ensure
  # Kill the server.
  sleep 1
  Process.kill(9, server_pid)
end
