# Write a ASIR::Transport::HTTP class
# Using HTTP::Client for transport send_request and receive_response.
# Using WEBrick for transport on the receive_request and send_response.
# Use the Marshal Coder for the Transport.

require 'rubygems'
require 'webrick'
gem 'httpclient'
require 'httpclient'
require 'uri'

$: << File.expand_path("../../../lib", __FILE__)
require 'asir'

module MathService
  include ASIR::Client
  def sum array
    # ???
  end
  extend self
end

module ASIR
  class Transport
    class HTTP < self
      attr_accessor :uri, :server

      # Client-side: HTTPClient

      def _send_request request
        client = ::HTTPClient.new
        # ???
      end

      # Should extract the content from the HTTPClient::Message
      def _receive_response opaque
        # ??? 
      end

      # Server-side: WEBrick
      
      # Extract the body from the request.
      def _receive_request rq
        # ???
      end

      # Set the Content-Type and body of the response.
      def _send_response result, rs
        # ??? 
      end

      # Parse the port and path of the #uri
      # Create a @server = WEBrick::HTTPServer on the port
      # Mount the path with a proc that calls server_request! with the HTTP request and response objects.
      def setup_server!
        # ???
        self
      end

      # Start the WEBbrick @server
      def start_server!
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
  t.logger = $stderr
  c = t.encoder = ASIR::Coder::Marshal.new
  c._log_enabled = true
  c.logger = $stderr

  # Setup and run the server in a child process.
  server_pid = Process.fork do
    # ??? 
    # ??? 
  end

  # system("curl http://localhost:#{port}/")

  MathService.client.transport = t

  MathService.client.sum([1, 2, 3])
ensure
  # Kill the server.
  Process.kill(9, server_pid)
end



