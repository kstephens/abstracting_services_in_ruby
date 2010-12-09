module ASIR
  IDENTITY_PROC = lambda { | x | x }
  module Configuration
    def self.included target
      super
      target.extend ClassMethods
    end

    def self.config_proc
      @@config_proc || IDENTITY_PROC
    end

    def self.config_proc= x
      @@config_proc = x
    end

    module ClassMethods
      attr_accessor :config_proc
    end

    def initialize *args
      super
      (self.class.config_proc || ASIR::Configuration.config_proc || IDENTITY_PROC).call(self)
    end
  end
end
