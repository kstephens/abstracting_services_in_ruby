
module ASIR
  # !SLIDE
  # Object Initialization
  #
  # Support initialization by Hash.
  #
  # E.g.:
  #   Foo.new(:bar => 1, :baz => 2)
  # ->
  #   obj = Foo.new; obj.bar = 1; obj.baz = 2; obj
  module Initialization
    def initialize opts = nil
      opts ||= EMPTY_HASH
      initialize_before_opts if respond_to? :initialize_before_opts
      opts.each do | k, v |
        send(:"#{k}=", v)
      end
      initialize_after_opts if respond_to? :initialize_after_opts
    end
  end
end

