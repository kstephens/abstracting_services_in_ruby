module ASIR
  # Adaptive Value.
  # Return a Numeric #value which adapts.
  # Useful for controlling adaptive retry sleep amounts or other
  # values that must be stochastic.
  #
  # #init must be specified.
  # #rand_factor should be a Float.
  #
  class AdaptiveValue
    attr_accessor :init, :min, :max, :add, :mult, :rand_factor

    def initialize opts = nil
      if opts
        opts.each do | k, v |
          send(:"#{k}=", v)
        end
      end
    end

    # Returns a new value limited by #min and #max after applying the addition of #rand_factor.
    def value
      v = @value || init_or_error
      v += v * rand(@rand_factor) if @rand_factor
      v = @min if @min && v < @min
      v = @max if @max && v > @max
      v
    end
    def value= x
      @value = x
    end

    # Returns a cached #value until #reset! or #new_value!.
    def value!
      @value_ ||= value
    end

    # Returns a new cached #value.
    def new_value!
      @value_ = nil
      value!
    end

    # Resets #value to #init.
    def reset!
      @value_ = @value = nil
      self
    end

    def to_i
      x = value.to_i
      adapt!
      x
    end

    def to_f
      x = value.to_f
      adapt!
      x
    end

    # Increments value by #add, if #add is set.
    # Multiplies value by #mult, if #mult is set.
    # Limits value by #min and #max.
    def adapt!
      @value ||= init_or_error
      @value += @add if @add
      @value *= @mult if @mult
      @value = @min if @min && @value < @min
      @value = @max if @max && @value > @max
      self
    end

    private
    def init_or_error
      @init or raise ArgumentError, "init: not set"
    end

  end
end

