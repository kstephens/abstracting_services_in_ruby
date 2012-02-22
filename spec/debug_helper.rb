require 'rubygems'
case (RUBY_PLATFORM rescue 'UNKNOWN')
when /java/
  # gem 'json_pure' # Fails to load under jruby 1.6.6
else
  gem 'json'
  case RUBY_VERSION
  when /^1\.9/
    gem 'ruby-debug19'
    gem 'simplecov'
    # require 'ruby-debug' # BROKEN in 1.9.3-head
  when /^1\.8/
    gem 'ruby-debug'
    gem 'rcov'
    require 'ruby-debug'
  end
end

