require 'asir/retry_behavior'

describe ASIR::RetryBehavior do
  let(:cls) do
    Class.new do
      include ASIR::RetryBehavior
      attr_accessor :sleeps
      def sleeps; @sleeps ||= [ ]; end
      def sleep x; sleeps << x; end
      def yields; @yields ||= [ ]; end
      def yielder &blk
        Proc.new do | kind, value |
          yields << [ kind, value ]
          blk.call kind, value
        end
      end
    end
  end
  subject { cls.new }

  it 'should retry only try_max times, then raise RetryError' do
    blk = subject.yielder do | kind, value |
      raise "Fail" if kind == :try
    end
    subject.try_max = 10
    lambda do
      subject.with_retry(&blk)
    end.should raise_error(ASIR::RetryBehavior::RetryError)
    subject.sleeps.should == [ ]
    subject.yields.select{|x| x[0] == :try}.map{|x| x[1]}.should == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    subject.yields.select{|x| x[0] == :rescue}.map{|x| x[1]}.size.should == 10
    subject.yields.select{|x| x[0] == :retry}.map{|x| x[1]}.size.should == 9
    subject.yields.select{|x| x[0] == :failed}.map{|x| x[1]}.size.should == 1
  end

  it 'should sleep for increasing amounts' do
    blk = subject.yielder do | kind, value |
      raise "Fail" if kind == :try
    end
    subject.try_max = 10
    subject.try_sleep = 10
    subject.try_sleep_increment = 2
    lambda do
      subject.with_retry(&blk)
    end.should raise_error(ASIR::RetryBehavior::RetryError)
    subject.sleeps.should == [10, 12, 14, 16, 18, 20, 22, 24, 26]
    subject.yields.select{|x| x[0] == :try}.map{|x| x[1]}.should == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    subject.yields.select{|x| x[0] == :rescue}.map{|x| x[1]}.size.should == 10
    subject.yields.select{|x| x[0] == :retry}.map{|x| x[1]}.size.should == 9
    subject.yields.select{|x| x[0] == :failed}.map{|x| x[1]}.size.should == 1

    subject.sleeps.clear
    subject.yields.clear
    lambda do
      subject.with_retry(&blk)
    end.should raise_error(ASIR::RetryBehavior::RetryError)
    subject.sleeps.should == [10, 12, 14, 16, 18, 20, 22, 24, 26]
  end
end

