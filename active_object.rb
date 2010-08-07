require 'thread' # Thread, Mutex, Queue

# !SLIDE
# Active Object pattern in Ruby
#
# * Kurt Stephens
# * 2010/08/06
# * http://kurtstephens.com/pub/active_object_pattern_in_ruby/

# !SLIDE
# Objective
#
# * Simplify inter-thread communication and management.
# * Provide Facade for objects in a thread-safe manner.
# * Allow objects to execute safely in their own thread.
# * Simple API.


# !SLIDE
# Design Pattern
#
# * http://en.wikipedia.org/wiki/Design_pattern_%28computer_science%29
# * http://en.wikipedia.org/wiki/Active_object

# !SLIDE
# Design
#
# * ActiveObject - module to mixin to existing classes.
# * ActiveObject::Proxy - object to receive and enqueue messages, owns thread to process queued messages.
# * ActiveObject::Message - encapsulate message for proxy for later execution by thread. 

# !SLIDE 
# ActiveObject Mixin
#
# Adds methods to construct an active Proxy object for instances of the including Class.
module ActiveObject
  # Generic API error.
  class Error < ::Exception; end

  # !SLIDE
  # Construct Proxy
  #
  # Return the ActiveObject::Proxy for this object.
  def _active_proxy
    @_active_proxy ||=
      Proxy.new(self)
  end

  # !SLIDE
  # Logging
  module Logging
    def _log_prefix; "  "; end
    def _log msg = nil
      msg ||= yield
      c = caller
      c = c[0]
      c = c =~ /`(.*)?'/ ? $1 : '<<unknown>>'
      $stderr.puts "#{_log_prefix}T@#{Thread.current.object_id} @#{object_id} #{self.class}##{c} #{msg}"
    end
  end

  # !SLIDE
  # Message
  #
  # Encapsulates message.
  # If block is provided, call it with result after invocation completion.
  class Message
    include Logging
    attr_accessor :proxy, :selector, :arguments, :block, :thread
    attr_accessor :result, :exception
    
    def initialize proxy, selector, arguments, block
      @proxy, @selector, @arguments, @block = proxy, selector, arguments, block
      @thread = ::Thread.current
    end
    
    def invoke!
      _log { "" }
      @result = @proxy._active_target.__send__(@selector, *@arguments)
      if @block
        @block.call(@result)
      end
    rescue Exception => exc
      @thread.raise exc
    end
  end

  # !SLIDE
  # Active Proxy
  #
  # Recieves messages on behalf of the target object.
  # Places message in its queue.
  # Manages a Thread to pull messages from its queue.
  class Proxy
    include Logging
    # Signal to tell thread to stop working on queue.
    class Stop < ::Exception; end

    def initialize target
      _log { "target=@#{target.object_id}" }
      @target = target
      @thread = nil
      @mutex = Mutex.new
      @queue = Queue.new
      @running = false
      @stopped = false
    end

    # !SLIDE
    # Enqueue Message
    #
    # Intercepts messages on behalf of @target.
    # Construct Message and place it in its queue.
    def method_missing selector, *arguments, &block
      _log { "#{selector} #{arguments.inspect}" }
      _active_enqueue(Message.new(self, selector, arguments, block))
    end

    # !SLIDE
    # Support

    def _active_target
      @target
    end

    def _active_thread
      @thread
    end

    def _active_enqueue message
      return if @stopped
      _log { "message=@#{message.object_id} @queue.size=#{@queue.size}" }
      @queue.push message
    end

    def _active_dequeue
      message = @queue.pop
      _log { "message=@#{message.object_id} @queue.size=#{@queue.size}" }
      message
    end

    # !SLIDE 
    # Start Thread
    #
    # Start a thread that blocks waiting for message to pull from its queue.
    def _active_start!
      _log { "" }
      @mutex.synchronize do
        raise Error, "Thread already exists" if @thread
        raise Error, "Proxy already running" if @running
        raise Error, "Thread is stopping"    if @stopped
        @stopped = false
        @thread = Thread.new do 
          _log { "Thread.new" }
          @running = true
          while @running
            begin
              _active_dequeue.invoke! if @running && ! @stopped
            rescue Stop => exc
              _log { "stopping via #{exc.class}" }
            end
          end
          _log { "stopped" }
          self
        end
        _log { "@thread=@T#{@thread.object_id}" }
        @thread
      end
      self
    end

    # !SLIDE
    # Stop Thread
    #
    # Sends exception to thread to tell it to stop.
    def _active_stop!
      _log { "" }
      t = @mutex.synchronize do
        return self if @stopped
        raise Error, "No Thread"          unless @thread
        raise Error, "Thread not running" unless @running
        @stopped = true
        @running = false
        t = @thread
        @thread = nil
        t
      end
      if t.alive?
        t.raise(Stop.new) rescue nil
      end
      self
    end
    # !SLIDE END
  end
end
# !SLIDE END

# !SLIDE 
# Example
#
# * Two objects send messages back to each other N times
# * Mixin ActiveObject to each class.

# !SLIDE
# Base class for example objects
class Base
  include ActiveObject

  # Prepare to do activity N times.
  def initialize
    @counter = 1
  end

  # Stop its ActiveObject::Proxy when @counter is depleated.
  def decrement_counter_or_stop
    if @counter > 0
      @counter -= 1
      true
    else
      _active_proxy._active_stop!
      false
    end
  end

  include ActiveObject::Logging
  def _log_prefix; ""; end
end

# !SLIDE
# class A
# Sends b.do_b
class A < Base
  attr_accessor :b

  def do_a msg
    _log { "msg=#{msg.inspect} @counter=#{@counter}" }
    if decrement_counter_or_stop
      b.do_b(msg) do | result | 
        _log { "result=#{result.inspect} " }
      end
      sleep(1)
    end
    [ :a, @counter ]
  end
end

# !SLIDE
# class B
# Sends a.do_a
class B < Base
  attr_accessor :a

  def do_b msg
    _log { "msg=#{msg.inspect} @counter=#{@counter}" }
    if decrement_counter_or_stop
      a.do_a(msg) do | result | 
        _log { "result=#{result.inspect} " }
      end
      sleep(1)
    end
    [ :b, @counter ]
  end
end

# !SLIDE :name example :capture_code_output true
# Running Example

a = A.new
b = B.new

a.b = b._active_proxy
b.a = a._active_proxy

a = a._active_proxy
b = b._active_proxy

a._active_start!
b._active_start!

a.do_a("Foo") 
b.do_b("Bar") 

a._active_thread.join rescue nil
b._active_thread.join rescue nil

$stderr.puts "DONE!"
exit 0

# !SLIDE END

# !SLIDE 
# Conclusion
#
# * Simple, easy-to-use API.
# * Does not require redesign of existing objects.
# * Supports asynchronous results.
#


