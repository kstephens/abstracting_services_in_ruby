module ASIR
  # Low-level ASIR configuration
  module Config
    @@client_method = :client
    def self.client_method; @@client_method; end
    def self.client_method= x; @@client_method = x; end
  end
end
