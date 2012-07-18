require File.expand_path('../spec_helper', __FILE__)

require 'asir'

describe "ASIR::Client" do
  attr_accessor :client, :data, :object

  before(:each) do
    self.data = { }
    transport = ASIR::Transport::Local.new
    self.object = ASIR::Test::TestObject.new(self)
    self.client = object.class.asir
    client.transport = transport
    client.transport.should == transport
  end

  it 'should return the same Proxy instance for a Module.' do
    object.class.asir.object_id.should == object.class.asir.object_id
  end

  it 'should return a cloned Proxy instances for each object.' do
    object.asir.object_id.should_not == client.object_id
    object.asir.object_id.should_not == object.asir.object_id
    object.asir.transport.object_id.should == client.transport.object_id
  end

  it 'should return a cloned Proxy for class.asir._configure.' do
    client._configure { | message, proxy | }.object_id.should_not == client.object_id
  end

  it 'should not return a cloned Proxy for object.asir._configure.' do
    c = object.asir
    c._configure { | message, proxy | }.object_id.should == c.object_id
  end

  it 'should handle _configure blocks' do
    proxy = object.asir._configure { | message, proxy |
      message[:test_proxy] = proxy
      message[:test_data] = :test
    }
    proxy.object_id.should_not == client.object_id
    proxy.object_id.should_not == object.asir.object_id
    proxy.return_argument :foo
    object.message[:test_data].should == :test
    object.message[:test_proxy].should == proxy
  end
end

