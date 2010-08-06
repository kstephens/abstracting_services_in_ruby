require 'thread' # Thread, Mutex, Queue

# !SLIDE
# Active Object pattern in Ruby
#

# !SLIDE
# Objective
#
# * Simplify inter-thread communication and managment.
# * Provide Facade for objects in a thread-safe manner.
# * Allow objects to execute safely in their own thread.
# * Simple API


# !SLIDE
# Design Pattern
#
# * http://en.wikipedia.org/wiki/Design_pattern_%28computer_science%29
# * http://en.wikipedia.org/wiki/Active_object
#

# !SLIDE
# Design
#
# * ActiveObject - module to mixin to existing classes.
# * ActiveObject::Proxy - object to receive and enqueue messages.
# * ActiveObject::Message - encapsulate message for proxy for later execution by thread. 

# !SLIDE 
# ActiveObject Mixin
#
# Adds methods to construct an active Proxy object for instances of the including Class.
module ActiveObject
  # !SLIDE
  # Construct Proxy
  #
  # Return the ActiveObject::Proxy for this object.
  def _active_proxy
    @_active_proxy ||=
      Proxy.new(self)
  end

  # !SLIDE
  # Active Proxy
  #
  # Recieves messages on behalf of the target object.
  # Places message in its queue.
  # Manages a Thread to pull messages from its queue.
  class Proxy
    # Signal to tell thread to stop working on queue.
    class Stop < ::Exception; end

    def initialize target
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
      _active_enqueue(Message.new(self, selector, arguments, block))
    end

    # !SLIDE
    # Message
    #
    # Encapsulates message.
    # If block is provided, call it with result after invocation completion.
    class Message
      attr_accessor :proxy, :selector, :arguments, :block, :thread
      attr_accessor :result, :exception

      def initialize proxy, selector, arguments, block
        @proxy, @selector, @arguments, @block = proxy, selector, arguments, block
        @thread = ::Thread.current
      end

      def invoke!
        @result = @proxy._active_target.__send__(@selector, *@arguments)
        if @block
          @block.call(@result)
        end
      rescue Exception => exc
        @thread.raise exc
      end
    end
    # !SLIDE END

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
      $stderr.puts "  #{Thread.current.object_id} _active_enqueue #{self.object_id} #{@queue.size}"
      @queue.push message
    end

    def _active_dequeue
      $stderr.puts "  #{Thread.current.object_id} _active_dequeue #{self.object_id} #{@queue.size}"
      @queue.pop
    end

    # !SLIDE END

    # !SLIDE 
    # Start Thread
    #
    # Start a thread that blocks waiting for message to pull from its queue.
    def _active_start!
      $stderr.puts "  #{Thread.current.object_id} _active_start! #{self.object_id}"
      @mutex.synchronize do
        raise Error, "Thread already exists" if @thread
        raise Error, "Proxy already running" if @running
        raise Error, "Thread is stopping"    if @stopped
        @stopped = false
        @thread = Thread.new do 
          @running = true
          $stderr.puts "  #{Thread.current.object_id} _active_start! running"
          while @running
            begin
              _active_dequeue.invoke! if @running && ! @stopped
            rescue Stop => exc
              $stderr.puts "  #{Thread.current.object_id} _active_start! stopping"
            end
          end
          $stderr.puts "  #{Thread.current.object_id} _active_start! stopped"
          self
        end
        @thread
      end
      self
    end

    # !SLIDE
    # Stop Thread
    #
    # Sends exception to thread to tell it to stop.
    def _active_stop!
      $stderr.puts "  #{Thread.current.object_id} _active_stop! #{self.object_id}"
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

# !SLIDE
# Base class for example objects
class Base
  include ActiveObject

  # Prepare to do activity N times.
  def initialize
    @counter = 5
  end

  # Stop it's Proxy when @counter is depleated.
  def decrement_counter_or_stop
    if @counter > 0
      @counter -= 1
      true
    else
      _active_proxy._active_stop!
      false
    end
  end
end

# !SLIDE
# class A
# Sends b.do_b
class A < Base
  attr_accessor :b

  def do_a msg
    $stderr.puts "#{Thread.current.object_id} #{self.class} do_a #{msg.inspect} #{@counter}"
    if decrement_counter_or_stop
      b.do_b(msg) { | result | $stderr.puts "#{Thread.current.object_id} A->do_b result = #{result.inspect}" }
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
    $stderr.puts "#{Thread.current.object_id} #{self.class} do_b #{msg.inspect} #{@counter}"
    if decrement_counter_or_stop
      a.do_a(msg) { | result | $stderr.puts "#{Thread.current.object_id} B->do_a result = #{result.inspect}" }
      sleep(1)
    end
    [ :b, @counter ]
  end
end

# !SLIDE
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


