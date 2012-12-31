#!/usr/bin/env ruby
$:.unshift File.expand_path('../../lib', __FILE__)
require 'asir/application'
require 'pp'

begin
  app = ASIR::Application.new
  spawn = app.spawn :hello do
    $stderr.puts "Hello from spawn #{$$}"
  end
  app.main do
    $stderr.puts "Hello from main #{$$}"
    spawn.go!
    spawn.wait
  end
rescue ::Exception
  $stderr.puts "ERROR: #{$!.inspect}\n  #{$!.backtrace * "\n  "}"
end
