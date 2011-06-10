# !SLIDE :capture_code_output true
# Local Process with delay option.

require 'example_helper'

pr DelayedService.client.
  _configure{|req| req.delay = 5}.
  do_it(Time.now)

# !SLIDE END
# EXPECT: : client process
# EXPECT: : DelayedService
# EXPECT: : pr: :ok
