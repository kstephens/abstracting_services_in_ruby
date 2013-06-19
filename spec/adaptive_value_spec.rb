require 'asir/adaptive_value'

describe ASIR::AdaptiveValue do
  it "should have a #value of #init." do
    av = ASIR::AdaptiveValue.new(:init => 5)
    av.value.should == 5
    av.value.should == 5
    av.value!.should == 5
  end

  it "should have a #value limited by #min." do
    av = ASIR::AdaptiveValue.new(:init => 5, :min => 10)
    av.value.should == 10
    av.value.should == 10
    av.value!.should == 10
  end

  it "should have a #value not limited by #min." do
    av = ASIR::AdaptiveValue.new(:init => 15, :min => 10)
    av.value.should == 15
    av.value.should == 15
    av.value!.should == 15
  end

  it "should have a #value limited by #max." do
    av = ASIR::AdaptiveValue.new(:init => 5, :max => 10)
    av.value.should == 5
    av.value.should == 5
    av.value!.should == 5
  end

  it "should have a #value not limited by #max." do
    av = ASIR::AdaptiveValue.new(:init => 15, :max => 10)
    av.value.should == 10
    av.value.should == 10
    av.value!.should == 10
  end

  it "should have a #value adjusted by #add." do
    av = ASIR::AdaptiveValue.new(:init => 1, :add => 2)
    av.value.should == 1
    av.value.should == 1
    av.adapt!
    av.value.should == 3
    av.value.should == 3
    av.value!.should == 3
    av.adapt!
    av.value.should == 5
    av.value.should == 5
    av.value!.should == 3
  end

  it "should have a #value adjusted by #mult." do
    av = ASIR::AdaptiveValue.new(:init => 10, :mult => 1.2)
    av.value.should == 10
    av.value.should == 10
    av.adapt!
    av.value.to_i.should == 12
    av.value.to_i.should == 12
    av.value!.to_i.should == 12
    av.adapt!
    av.value.to_i.should == 14
    av.value.to_i.should == 14
    av.value!.to_i.should == 12
  end

  it "should have an adapting #to_i and #to_f value." do
    av = ASIR::AdaptiveValue.new(:init => 10, :mult => 1.2)
    av.to_i.should == 10
    av.to_f.should be_within(0.1).of(12.0)
    av.to_f.should be_within(0.1).of(14.4)
    av.to_f.should be_within(0.01).of(17.28)
    av.to_i.should == 20
  end

  it "should have a #value adjusted by #rand_factor." do
    av = ASIR::AdaptiveValue.new(:init => 10, :rand_factor => 0.5)
    def av._ri
      @_ri ||= -1
      @_ri += 1
    end
    def av._rv
      @_rv ||= (0...10).to_a
    end
    def av.rand scale
      (_rv[_ri % _rv.size] / 10.0) * scale
    end

    av.value.should == 10
    av.value.should == 10.5
    av.value!.should == 11.0
    av.value.should == 11.5
    av.value.should == 12.0
    av.value!.should == 11.0
  end

  it "should raise error if #init is not set." do
    av = ASIR::AdaptiveValue.new(:rand_factor => 0.5)
    lambda do
      av.value
    end.should raise_error(ArgumentError, /init: not set/)
  end
end
