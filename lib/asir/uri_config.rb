require 'asir'
require 'uri'

module ASIR
  module UriConfig
    attr_accessor :uri, :scheme, :host, :port
    alias :protocol :scheme
    alias :protocol= :scheme=
    alias :address :host
    alias :address= :host=

    def uri
      @uri ||= "#{scheme}://#{host}:#{port}"
    end

    def _uri
      @_uri ||=
        URI === @uri ? @uri : URI.parse(uri)
    end

    def scheme
      @scheme ||=
        @uri ? _uri.scheme : S_TCP
    end
    S_TCP = 'tcp'.freeze

    def host
      @host ||=
        @uri ? _uri.host : S_LOCALHOST
    end
    S_LOCALHOST = '127.0.0.1'.freeze

    def port
      @port ||=
        @uri ? _uri.port :
          (raise Error, "#{self.class}: port not set.")
    end

  end
end
