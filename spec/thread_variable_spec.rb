require 'asir/thread_variable'

class ASIR::ThreadVariable::Test
  include ASIR::ThreadVariable
  cattr_accessor_thread :tv1
  cattr_accessor_thread :tv2, :initialize => '1'
  cattr_accessor_thread :tv3, :default => '2'
  cattr_accessor_thread :tv4, :transform => '__val.to_s'
  attr_accessor_thread  :iv1
  attr_accessor :iv2
end

describe 'ASIR::ThreadVariable' do
  def tc
    @tc ||=
      ASIR::ThreadVariable::Test
  end
  def ti
    @ti ||=
      tc.new
  end

  it 'cattr_accessor_thread handles concurrency' do
    th1 = Thread.new {
      tc.tv1.should == nil
      tc.tv1 = 1
      tc.tv1.should == 1
      tc.with_attr! :tv1, 2 do
        tc.tv1.should == 2
      end
      tc.tv1.should == 1
      tc.clear_tv1.should == tc
      tc.tv1.should == nil
    }
    th2 = Thread.new { 
      tc.tv1.should == nil
      tc.tv1 = 2
      tc.tv1.should == 2
      tc.clear_tv1.should == tc
      tc.tv1.should == nil
    }
    th1.join
    th2.join
  end

  it 'attr_accessor_thread handles concurrency' do
    th1 = Thread.new do
      begin
        ti.iv1.should == nil
        ti.iv1 = 1
        ti.iv1.should == 1
        ti.with_attr! :iv1, 2 do
          ti.iv1.should == 2
        end
        ti.iv1.should == 1
        ti.clear_iv1.should == ti
        ti.iv1.should == nil
      rescue Exception => exc
        raise exc.class, "In th1: #{exc.message}", exc.backtrace
      end
    end
    th2 = Thread.new do
      begin
        ti.iv1.should == nil
        ti.iv1 = 2
        ti.iv1.should == 2
        ti.clear_iv1.should == ti
        ti.iv1.should == nil
      rescue Exception => exc
        raise exc.class, "In th2: #{exc.message}", exc.backtrace
      end
    end
    th1.join
    th2.join
  end

  it 'cattr_accessor_thread basic options' do
    tc.tv1.should == nil
    tc.tv1 = 1
    tc.tv1.should == 1
    tc.clear_tv1
    tc.tv1.should == nil
  end

  it 'cattr_accessor_thread :initialize option' do
    tc.tv2.should == 1
    tc.tv2 = 2
    tc.tv2.should == 2
    tc.clear_tv2
    tc.tv2.should == 1
  end

  it 'cattr_accessor_thread :default option' do
    tc.tv3.should == 2
    tc.tv3 = 3
    tc.tv3.should == 3
    tc.clear_tv3
    tc.tv3.should == 2
  end

  it 'cattr_accessor_thread :transform option' do
    tc.tv4.should == ''
    tc.tv4 = 101
    tc.tv4.should == '101'
    tc.tv4 = '102'
    tc.tv4.should == '102'
    tc.clear_tv4
    tc.tv4.should == ''
  end

  it 'attr_accessor_thread :with_attr!' do
    ti.iv1.should == nil
    ti.with_attr! :iv1, :value do
      ti.iv1.should == :value
      ti.with_attr! :iv1, :value2 do
        ti.iv1.should == :value2
      end
      ti.iv1.should == :value
    end
    ti.iv1.should == nil
  end

  it 'attr_accessor :with_attr!' do
    ti.iv2.should == nil
    ti.with_attr! :iv2, :value do
      ti.iv2.should == :value
      ti.with_attr! :iv2, :value2 do
        ti.iv2.should == :value2
      end
      ti.iv2.should == :value
    end
    ti.iv2.should == nil
  end
end

