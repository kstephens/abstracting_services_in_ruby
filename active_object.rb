require 'thread' # Thread, Mutex, Queue

module ActiveObject
  def self.included target
    super target
    target.extend ClassMethods
  end

  module ClassMethods
  end

  def _active_proxy
    @_active_proxy ||=
      Proxy.new(self)
  end

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

    def method_missing selector, *arguments, &block
      _active_enqueue(Message.new(self, selector, arguments, block))
    end

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
  end
end

class Base
  include ActiveObject
  def initialize
    @counter = 5
  end
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

