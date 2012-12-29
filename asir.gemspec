# -*- encoding: utf-8 -*-
# -*- ruby -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'asir/version'

Gem::Specification.new do |s|
  gem = s
  s.name = %q{asir}
  s.version = ASIR::VERSION
  s.authors = ["Kurt Stephens"]
  s.email = %q{ks.ruby@kurtstephens.com}
  s.description = %q{Abstracting Services in Ruby}
  s.summary = %q{Abstracting Services in Ruby}
  s.homepage = %q{http://github.com/kstephens/abstracting_services_in_ruby}

  s.files         = `git ls-files`.split($/)
  s.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.extra_rdoc_files = [ "README.textile" ]
  s.rdoc_options = ["--charset=UTF-8"]

  gem.add_dependency "uuid", "~> 2.3.6"
  s.add_dependency "httpclient", "~> 2.3.0"
  s.add_dependency "rack", "~> 1.4.1"

  s.add_development_dependency 'rake', '>= 0.9.0'
  s.add_development_dependency 'rspec', '~> 2.12.0'
  s.add_development_dependency 'simplecov', '>= 0.1'
  if (RUBY_ENGINE rescue 'UNKNOWN') =~ /jruby/i
    s.add_development_dependency 'spoon', '>= 0.0.1'
  end
end

