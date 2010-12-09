# Write a ASIR::Transport::HTTP class that uses HTTP::Client for transport send_response and receive_response.

require 'rubygems'
require 'webrick'
gem 'httpclient'
require 'httpclient'
require 'uri'

$: << File.expand_path("../../../lib", __FILE__)
require 'asir'

require 'math_service'
MathService.send(:include, ASIR::Client)

module ASIR
  class Transport
    class HTTP < self
      attr_accessor :uri, :server

      # Client-side: HTTPClient

      def _send_request request
        client = ::HTTPClient.new
        result = client.post(uri, request)
        opaque = result # ???
      end

      def _receive_response opaque
        # $stderr.puts "_receive_response opaque.content = #{opaque.content.inspect}"
        opaque.content.to_s
      end

      # Server-side: WEBrick 
      def _receive_request rq
        rq.body
      end

      def _send_response result, rs
        rs['Content-Type'] = 'application/binary'
        rs.body = result
      end

      def setup_server!
        u = URI.parse(uri)
        port = u.port
        path = u.path
        @server = WEBrick::HTTPServer.new(:Port => port)
        @server.mount_proc path, lambda { | rq, rs |      
          serve_request! rq, rs
        }
        self
      end

      def start_server!
        @server.start
        self
      end
    end
  end
end


port = 3001
begin
  t = ASIR::Transport::HTTP.new(:uri => "http://localhost:#{port}")
  t._log_enabled = true
  t.logger = $stderr
  c = t.encoder = ASIR::Coder::Marshal.new
  c._log_enabled = true
  c.logger = $stderr

  server_pid = Process.fork do
    t.setup_server!
    t.start_server!
  end

  MathService.client.transport = t
  MathService.client.sum([1, 2, 3])
ensure
  Process.kill(9, server_pid)
end



