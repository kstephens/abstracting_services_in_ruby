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
# * Provide a thread-safe Facade to object methods.
# * Select ActiveObject Facade at run-time.
# * Allow objects to execute work safely in their own thread.
# * Simple API.


# !SLIDE
# Design Pattern
#
# * http://en.wikipedia.org/wiki/Design_pattern_%28computer_science%29
# * http://en.wikipedia.org/wiki/Active_object

# !SLIDE
# Design
#
# * ActiveObject::Mixin - module to mixin to existing classes.
# * ActiveObject::Facade - object to receive and enqueue messages, owns thread to process queued messages.
# * ActiveObject::Message - encapsulate message for proxy for later execution by thread. 

# !SLIDE 
# ActiveObject Mixin
#
# Adds methods to construct an active Facade object for instances of the including Class.
module ActiveObject
  # Generic API error.
  class Error < ::Exception; end

  # !SLIDE
  # Logging
  module Logging
    def _log_prefix; "  "; end
    def _log msg = nil
      msg ||= yield
      c = caller
      c = c[0]
      c = c =~ /`(.*)?'/ ? $1 : '<<unknown>>'
      namespace = Module === self ? "#{self.name}." : "#{self.class.name}#"
      $stderr.puts "#{_log_prefix}T@#{Thread.current.object_id} @#{object_id} #{namespace}#{c} #{msg}"
    end
  end

  # !SLIDE
  # Facade
  #
  # Intercepts messages on behalf of the target object.
  # Subclasses of Facade handle delivery of message to the target object.
  class Facade
    include Logging

    def initialize target
      _log { "target=@#{target.object_id}" }
      @target = target
      target._active_facade = self
    end

    # !SLIDE
    # Identity Facade
    #
    # Immediately delegate to the target.
    class Identity < self
      # !SLIDE
      # Delegate message directly
      #
      # Delegate messages immediately to @target.
      # Does not bother to construct a Message.
      def method_missing selector, *arguments, &block
        _log { "#{selector} #{arguments.inspect}" }
        result = @target.__send__(selector, *arguments)
        if block
          block.call(result)
        else
          nil
        end
      end

      # Nothing to start; this Facade is not active.
      def _active_start!
        self
      end

      # Nothing to stop; this Facade is not active.
      def _active_stop!
        # NOTHING.
        self
      end
    end

    # !SLIDE
    # Active Facade
    #
    # Recieves message on behalf of the target object.
    # Places Message in its Queue.
    # Manages a Thread to pull Messages from its Queue for invocation.
    class Active < self
      # Signal Thread to stop working on queue.
      class Stop < ::Exception; end

      def initialize target
        super
        @thread = nil
        @mutex = Mutex.new
        @queue = Queue.new
        @running = false
        @stopped = false
        @@active_facades << self
      end

      # !SLIDE
      # Enqueue Message
      #
      # Intercept message on behalf of @target.
      # Construct Message and place it in its Queue.
      def method_missing selector, *arguments, &block
        _log { "#{selector} #{arguments.inspect}" }
        _active_start! unless @running
        _active_enqueue(Message.new(self, selector, arguments, block))
      end

      # !SLIDE
      # Message
      #
      # Encapsulates Ruby message.
      # If block is provided, call it with result after Message invocation.
      class Message
        include Logging
        attr_accessor :facade, :selector, :arguments, :block, :thread
        attr_accessor :result, :exception
        
        def initialize facade, selector, arguments, block
          _log { "facade=@#{facade.object_id} selector=#{selector.inspect} arguments=#{arguments.inspect}" }
          @facade, @selector, @arguments, @block = facade, selector, arguments, block
          @thread = ::Thread.current
        end
        
        def invoke!
          _log { "@facade=@#{@facade.object_id}" }
          @result = @facade._active_target.__send__(@selector, *@arguments)
          if @block
            @block.call(@result)
          end
        rescue Exception => exc
          @thread.raise exc
        end
      end
      
      # !SLIDE
      # Queuing
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
      # Start worker Thread
      #
      # Start a Thread that blocks waiting for Message in its Queue.
      def _active_start!
        _log { "" }
        @mutex.synchronize do
          return self if @running || @thread || @stopped
          @stopped = false
          @thread = Thread.new do 
            _log { "Thread.new" }
            @running = true
            Active.active_facades << self
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
      # Stop worker Thread
      #
      # Sends exception to Thread to tell it to stop.
      def _active_stop!
        _log { "" }
        t = @mutex.synchronize do
          return self if @stopped || ! @thread || ! @running
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
      rescue Stop => exc
        # Handle Stop thrown to main thread after last Thread#join.
        self
      end
    end


    # !SLIDE
    # Support

    def _active_target
      @target
    end

    def _active_thread
      @thread
    end

    def self.active_facades
      @@active_facades ||= [ ]
    end

    def self.join
      active_facades.each do | f |
        if thr = f._active_thread
          f._log { "join thr=T@#{thr.object_id}" }
          thr.join rescue nil
        end
      end
    end
    # !SLIDE END

    # !Slide
    # Multiple workers
    #
    # Distributor distributes work to Threads via round-robin.
    class Distributor < Identity
      def initialize target
        super
        @mutex = Mutex.new
        @target_list = [ ]
        @target_index = 0
      end

      def method_missing selector, *arguments, &block
        _log { "#{selector} #{arguments.inspect}" }
        if @target_list.empty?
          super
        else
          target = nil
          @mutex.synchronize do
            target = @target_list[@target_index]
            @target_index = (@target_index + 1) % @target_list.size
          end
          raise Error, "No target" unless target
          target.method_missing(selector, *arguments, &block)
        end
      end

      def _active_add_distributee! cls, new_target = nil
        @mutex.synchronize do
          target = new_target || (Proc === @target ? @target.call : @target.clone)
          @target_list << cls.new(target)
        end
      end
    end
  end


  # !SLIDE
  # Glue Facade to including Class.
  module Mixin
    def self.included target
      super
      target.instance_eval do 
        alias :_new_without_active_facade :new
      end
      target.extend(ClassMethods)
    end
    
    attr_accessor :_active_facade

    # !SLIDE
    # Facade interface.
    module ClassMethods
      include Logging

      # The Facade subclass to use for instances of the including Class.
      attr_accessor :active_facade
      
      # Override including class' .new method
      # to wrap actual object with a 
      # Facade instance.
      def new *arguments, &block
        _log { "arguments=#{arguments.inspect}" }
        obj = super(*arguments, &block)
        facade = (active_facade || Facade::Identity).new(obj)
        _log { "facade=@#{facade.object_id}" }
        facade
      end
    end
  end
  # !SLIDE END

end
# !SLIDE END

# !SLIDE 
# Example
#
# * Two objects send messages back and forth to each other N times.
# * Mixin ActiveObject to each class.

# !SLIDE
# Base class for example objects
class Base
  include ActiveObject::Mixin

  # Prepare to do activity N times.
  def initialize
    _log { "" }
    @counter = 1
  end

  # Stop its ActiveObject::Facade when @counter is depleated.
  def decrement_counter_or_stop
    if @counter > 0
      @counter -= 1
      true
    else
      _active_facade._active_stop!
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

# !SLIDE :name example_1 :capture_code_output true
# Example with Identity Facade

puts "Example with Identity Facade" # !SLIDE IGNORE
A.active_facade = B.active_facade = nil # ActiveObject::Facade::Identity
a = A.new
b = B.new

a.b = b
b.a = a

a.do_a("Foo") 
b.do_b("Bar") 

ActiveObject::Facade::Active.join

$stderr.puts "DONE!"

# !SLIDE END

# !SLIDE :name example_2 :capture_code_output true
# Example with Active Facade

puts "Example with Active Facade" # !SLIDE IGNORE
A.active_facade = B.active_facade = ActiveObject::Facade::Active
a = A.new
b = B.new

a.b = b
b.a = a

a.do_a("Foo") 
b.do_b("Bar") 

ActiveObject::Facade::Active.join

$stderr.puts "DONE!"

# !SLIDE END

# !SLIDE :name example_3 :capture_code_output true
# Example with Active Distributor

puts "Example with Active Distributor" # !SLIDE IGNORE
A.active_facade = B.active_facade = ActiveObject::Facade::Distributor
a = A.new
b = B.new

a.b = b
b.a = a

a._active_add_distributee! ActiveObject::Facade::Active
a._active_add_distributee! ActiveObject::Facade::Active
b._active_add_distributee! ActiveObject::Facade::Active
b._active_add_distributee! ActiveObject::Facade::Active

a.do_a("Foo") 
b.do_b("Bar") 

ActiveObject::Facade::Active.join

$stderr.puts "DONE!"

# !SLIDE END

# !SLIDE 
# Conclusion
#
# * Simple, easy-to-use API.
# * Does not require redesign of existing objects.
# * Supports asynchronous results.
#

exit 0

