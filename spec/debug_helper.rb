require 'rubygems'
case (RUBY_PLATFORM rescue 'UNKNOWN')
when /java/
  gem 'json_pure'
else
  gem 'json'
  case RUBY_VERSION
  when /^2\./
    gem 'simplecov'
  when /^1\.9/
    gem 'ruby-debug19'
    gem 'simplecov'
    # require 'ruby-debug' # BROKEN in 1.9.3-head
  when /^1\.8/
    gem 'ruby-debug'
    gem 'simplecov'
    require 'ruby-debug'
  end
end

