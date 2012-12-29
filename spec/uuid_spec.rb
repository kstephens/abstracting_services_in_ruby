require 'asir/uuid'

describe "ASIR::UUID" do
  attr_accessor :u
  before { @u = ASIR::UUID }

  it 'should return a UUID from #new_uuid.' do
    x = u.new_uuid
    x.should =~ ASIR::UUID::UUID_REGEX
  end

  it 'should return unique result from #new_uuid.' do
    a = [ ]
    10.times do
      x = u.new_uuid
      x.should =~ ASIR::UUID::UUID_REGEX
      a << u.new_uuid
    end
    a.uniq.size.should == 10
  end

  it 'should single unique result per process from #process_uuid.' do
    a = [ ]
    10.times do
      x = u.process_uuid
      x.should =~ ASIR::UUID::UUID_REGEX
      a << u.process_uuid
      a << u.generate
    end
    a.uniq.size.should == 11
  end

  it 'should single unique result per process from #counter_uuid.' do
    a = [ ]
    10.times do
      x = u.counter_uuid
      x.should =~ ASIR::UUID::COUNTER_UUID_REGEX
      a << x
      a << u.process_uuid
      a << u.generate
    end
    a.uniq.size.should == 21
  end

  it 'should single unique result per Thread from #thread_uuid.' do
    a = [ ]
    10.times do
      x = u.thread_uuid
      x.should =~ ASIR::UUID::COUNTER_UUID_REGEX
      a << x
      a << u.generate
      a << u.process_uuid
    end
    a.uniq.size.should == 12

    a = [ ]
    b = [ ]
    t1 = Thread.current
    t2 = Thread.new do
      10.times do
        b << u.thread_uuid(t1)
        b << u.thread_uuid(t2)
      end
    end
    10.times do
      a << u.thread_uuid(t1)
      a << u.thread_uuid(t2)
    end

    t2.join
    c = a + b
    c.uniq.size.should == 2
  end

end

