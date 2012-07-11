require File.expand_path('../spec_helper', __FILE__)

$:.unshift File.expand_path('../../example', __FILE__)

require 'asir'

describe "ASIR::Transport" do
  attr_accessor :transport, :data, :object

  before(:each) do
    self.data = { }
    self.transport = ASIR::Transport::Local.new
    self.object = ASIR::Test::TestObject.new(self)
    object.class.client.transport = transport
    object.class.client.transport.should == self.transport
  end

  it 'should return result.' do
    result = object.client.return_argument :this_value
    object.arg.should == :this_value
    result.should == :this_value
  end

  it 'should set ASIR::Transport only during processing.' do
    ASIR::Transport.current.should == nil
    object.client.return_argument :this_value
    ASIR::Transport.current.should == nil
    object.transport.class.should == transport.class
  end

  it 'should not create clone of ASIR::Transport during processing.' do
    object.client.return_argument :this_value
    object.transport.object_id.should == transport.object_id
  end

  it 'should set ASIR::Transport#message during processing.' do
    transport.message.should == nil
    object.client.return_argument :this_value
    transport.message.should == nil
    object.transport.message.should == nil
    object.message.class.should == ASIR::Message
  end

  it 'should handle on_result_exception callbacks' do
    _transport, _result = nil, nil
    p = lambda do | transport, result |
      _transport = transport
      _result = result
    end
    transport.on_result_exception = p

    cls = ::ASIR::Test::TestError
    msg = 'This Message'.freeze

    object.client.transport.on_result_exception.should == p

    expect {
      object.client.raise_exception! cls, msg
    }.to raise_error

    object.msg.should == msg
    object.message.class.should == ASIR::Message
    object.transport.on_result_exception.class.should == Proc

    result = object.message.result
    result.class.should == ASIR::Result

    exc = result.exception
    exc.class.should == ASIR::EncapsulatedException
    exc.exception_class.should == cls.name
    exc.exception_message.should == msg
    exc.exception_backtrace.class.should == Array

    _transport.should == object.transport

    _result.class.should == ASIR::Result
    _result.object_id.should == result.object_id

    _result.message.class.should == ASIR::Message
    _result.message.object_id.should == result.message.object_id
    _result.exception.should == exc
  end
end

