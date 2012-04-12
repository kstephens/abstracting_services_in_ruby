require 'asir/thread_variable'

class ASIR::ThreadVariable::Test
  include ASIR::ThreadVariable
  cattr_accessor_thread :tv1
  cattr_accessor_thread :tv2, :initialize => '1'
  cattr_accessor_thread :tv3, :default => '2'
  cattr_accessor_thread :tv4, :transform => '__val.to_s'
end

describe 'ASIR::ThreadVariable' do
  def tc
    ASIR::ThreadVariable::Test
  end

  it 'cattr_accessor_thread handles concurrency' do
    th1 = Thread.new {
      tc.tv1.should == nil
      tc.tv1 = 1
      tc.tv1.should == 1
      tc.clear_tv1
      tc.tv1.should == nil
    }
    th2 = Thread.new { 
      tc.tv1.should == nil
      tc.tv1 = 2
      tc.tv1.should == 2
      tc.clear_tv1
      tc.tv1.should == nil
    }
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
end

