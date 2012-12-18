#
# !SLIDE :capture_code_output true
# One-way, asynchronous thread service

require 'example_helper'
begin
  Email.asir.transport = t =
    ASIR::Transport::Thread.new
  spawned_thread = nil
  t.after_thread_new = lambda do | transport, message, thread |
    spawned_thread = thread
    $stderr.puts "\n  #{$$}: Spawned Thread #{thread.inspect}"
  end

  pr Email.asir.send_email(:pdf_invoice,
                             :to => "user@email.com",
                             :customer => @customer)

  spawned_thread.join
end

# !SLIDE END
# EXPECT: : Spawned Thread
# EXPECT: : client process
# EXPECT: : Email.send_mail :pdf_invoice
# EXPECT: : pr: nil

