require 'asir'

require 'rubygems'
require 'webrick'
gem 'httpclient'
require 'httpclient'
require 'uri'

module ASIR
  class Transport
    # !SLIDE
    # HTTP Transport
    #
    # HTTP Transport using HTTPClient and WEBrick.
    class HTTP < self
      attr_accessor :uri, :server, :debug

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
        $stderr.puts "  #{self.class}#_receive_request: rq.body = #{rq.body.to_s.inspect}\n" if @debug
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


