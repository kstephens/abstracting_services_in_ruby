module ASIR
  ::RUBY_ENGINE = 'UNKNOWN'.freeze unless defined? ::RUBY_ENGINE
  def self.ruby_path
    @@ruby_path ||=
      begin
        require 'rbconfig'
        File.join(RbConfig::CONFIG["bindir"],
             RbConfig::CONFIG["RUBY_INSTALL_NAME"] +
             RbConfig::CONFIG["EXEEXT"]).freeze
      end
  end
end
