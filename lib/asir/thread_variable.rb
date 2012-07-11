module ASIR

# Adds Thread-based class and instance variables.
module ThreadVariable
  def self.included target
    super
    target.instance_eval do
      include CommonMethods
      extend  CommonMethods
      extend  ModuleMethods
    end
  end
  DEBUG = false

  module CommonMethods
    # Yields to block while self.name = value.
    # Restores self.name after yield.
    def with_attr! name, value
      save_value = send(name)
      send(::ASIR::ThreadVariable.setter(name), value)
      yield
    ensure
      send(::ASIR::ThreadVariable.setter(name), save_value)
    end
  end

  def self.setter sym
    SETTER[sym] ||= :"#{sym}="
  end
  SETTER = { }

  module ModuleMethods
    # Defines a Module or Class attribute stored in Thread.current.
    def mattr_accessor_thread *names
      mattr_getter_thread *names
      mattr_setter_thread *names
    end
    alias :cattr_accessor_thread :mattr_accessor_thread

    # Defines a Module or Class attribute setter stored in Thread.current.
    def mattr_setter_thread *names
      opts = Hash === names[-1] ? names.pop : EMPTY_HASH

      transform = opts[:setter_transform]
      transform = "__val = (#{transform})" if transform

      names.each do | name |
        instance_eval(expr = <<"END", __FILE__, __LINE__)
def self.#{name}= __val
  #{transform}
  Thread.current[:'#{self.name}.#{name}'] = [ __val ]
end
END
        # $stderr.puts "#{expr}"
      end
    end
    alias :cattr_setter_thread :mattr_setter_thread

    # Defines a class attribute getter stored in Thread.current.
    #
    # Options:
    #
    #   :initialize -- String: expression to initialize the variable is undefined.
    #   :default    -- String: expression to return if the variable value if undefined.
    #   :transform  -- String: expression to transform the __val variable before returning.
    #
    # Also defines clear_NAME method that undefines the thread variable.
    def mattr_getter_thread *names
      opts = Hash === names[-1] ? names.pop : EMPTY_HASH

      initialize = opts[:initialize]
      initialize = "||= [ #{initialize} ]" if initialize

      default = opts[:default]
      default = "__val ||= [ #{default} ]" if default

      transform = opts[:transform]
      transform = "__val = (#{transform})" if transform

      names.each do | name |
        instance_eval(expr = <<"END", __FILE__, __LINE__)
def self.clear_#{name}
  Thread.current[:'#{self.name}.#{name}'] = nil
  self
end

def self.#{name}
  __val = Thread.current[:'#{self.name}.#{name}'] #{initialize}
  #{default}
  __val &&= __val.first
  #{transform}
  __val
end
END
        # $stderr.puts "#{expr}"
      end
    end
    alias :cattr_getter_thread :mattr_getter_thread

    # TODO: clear instance thread variables when instance is GCed.
    def attr_accessor_thread *names
      attr_getter_thread *names
      attr_setter_thread *names
    end

    def attr_setter_thread *names
      opts = Hash === names[-1] ? names.pop : EMPTY_HASH

      transform = opts[:setter_transform]
      transform = "__val = (#{transform})" if transform

      names.each do | name |
        expr = [ <<"END", __FILE__, __LINE__ ]
def clear_#{name}
  ((Thread.current[:'#{self.name}\#'] ||= { })[self.object_id] || { }).delete(:'#{name}')
  self
end

def #{name}= __val
  #{transform}
  thread_attrs[:'#{name}'] = [ __val ]
end
END
        $stderr.puts "expr::\n#{expr}\n====" if opts[:debug] || DEBUG
        class_eval *expr
      end
    end

    def attr_getter_thread *names
      opts = Hash === names[-1] ? names.pop : EMPTY_HASH

      expr = [ <<"END", __FILE__, __LINE__ ]
def self.attr_thread_hash(obj)
  thr = Thread.current
  ObjectSpace.define_finalizer(obj) do | oid |
    (thr[:'#{self.name}\#'] ||= { }).delete(oid)
  end
  { }
end

def thread_attrs
  (Thread.current[:'#{self.name}\#'] ||= { })[self.object_id] ||= #{self.name}.attr_thread_hash(self)
end

def attr_thread_clear_all! oid = self.object_id
  (Thread.current[:'#{self.name}\#'] ||= { }).delete(oid)
end
END
      $stderr.puts "expr::\n#{expr}\n====" if opts[:debug] || DEBUG
      class_eval *expr

      initialize = opts[:initialize]
      if initialize
        initialize = "||= { }"
      end

      default = opts[:default]
      default = "__val ||= [ #{default} ]" if default

      transform = opts[:transform]
      transform = "__val = (#{transform})" if transform

      names.each do | name |
        expr = [ <<"END", __FILE__, __LINE__ ]
def #{name}
  __val = (thread_attrs[:'#{name}'] #{initialize})
  #{default}
  __val &&= __val.first
  #{transform}
  __val
end
END
        $stderr.puts "expr::\n#{expr}\n====" if opts[:debug] || DEBUG
        class_eval *expr
      end
    end

  end # module

  EMPTY_HASH = { }.freeze
end # module

end # module
