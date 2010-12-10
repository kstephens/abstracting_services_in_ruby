module ASIR
  IDENTITY_PROC = lambda { | x | x }
  module Configuration
    def self.included target
      super
      target.extend ClassMethods
    end

    # Global default config_proc
    def self.config_proc_hash
      @@config_proc_hash ||= { }
    end

    module ClassMethods
      def config_proc
        ASIR::Configuration.config_proc_hash[self]
      end
      def config_proc= x
        ASIR::Configuration.config_proc_hash[self] = x
      end
    end

    def initialize *args
      super
      ch = ASIR::Configuration.config_proc_hash
      (self.class.ancestors.map{|m| ch[m]}.compact.first ||
       ch[nil] || 
       IDENTITY_PROC
       ).call(self)
    end
  end
end
