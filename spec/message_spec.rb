require File.expand_path('../spec_helper', __FILE__)

$:.unshift File.expand_path('../../example', __FILE__)

require 'asir'

describe "ASIR::Message" do
  attr_accessor :message, :data, :object

  before(:each) do
    self.data = { }
    self.object = ASIR::Test::TestObject.new(self)
    self.message = ASIR::Message.new(object, nil, nil, nil, nil)
  end

  it 'should return result.' do
    message.receiver.should == object
    message.selector.should == nil
    message.arguments.should == nil
    message.block.should == nil
    message.selector = :return_argument
    message.arguments = [ :this_value ]
    result = message.invoke!
    object.arg.should == :this_value
    result.class.should == ASIR::Result
    result.result.should == :this_value
    result.message.should == message
    result.exception.should == nil
  end

  it 'should capture exceptions.' do
    cls = ::ASIR::Test::TestError
    msg = "This message".freeze
    message.selector = :raise_exception!
    message.arguments = [ cls, msg ]
    result = message.invoke!
    object.cls.should == cls
    object.msg.should == msg
    result.class.should == ASIR::Result
    result.result.should == nil
    result.message.should == message
    exc = result.exception
    exc.class.should == ASIR::EncapsulatedException
    exc.exception_class.should == cls.name
    exc.exception_message.should == msg
    exc.exception_backtrace.class.should == Array
  end

  it 'should capture Unforwardable exceptions.' do
    cls = ::ASIR::Error::Unforwardable.unforwardable.first
    cls.should_not == nil
    msg = "This message".freeze
    message.selector = :raise_exception!
    message.arguments = [ cls, msg ]
    result = message.invoke!
    object.cls.should == cls
    object.msg.should == msg
    result.class.should == ASIR::Result
    result.result.should == nil
    result.message.should == message
    exc = result.exception
    exc.class.should == ASIR::EncapsulatedException
    exc.exception_class.should == 'ASIR::Error::Unforwardable'
    exc.exception_message.should == "#{cls.name} #{msg}"
    exc.exception_backtrace.class.should == Array
  end
end

