require 'rubygems'
case (RUBY_PLATFORM rescue 'UNKNOWN')
when /java/
  # NOTHING!
else
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

