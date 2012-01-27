#!/usr/bin/env ruby
require 'pp'

class PhonyProc
  def initialize hash
    @data = hash
  end
  def to_proc
    self
  end
  def call lang, *args, &blk
    @data[lang].call(*args, &blk)
  end
end

def with_block something, &block
  pp block
  block.call(:ruby, something)
end

with_block(123, &PhonyProc.new(:ruby => proc { | x | x * 2 },
                               :js => 'function (x) { return x * 2; }'))

=begin

 > ruby lab/phony_proc.rb 
lab/phony_proc.rb:21: PhonyProc#to_proc should return Proc (TypeError)

wah-wah.. :(

=end
