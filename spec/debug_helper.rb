require 'rubygems'
case (RUBY_PLATFORM rescue 'UNKNOWN')
when /java/
  gem 'json_pure'
else
  gem 'json'
  gem 'simplecov'
end

