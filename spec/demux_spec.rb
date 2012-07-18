require File.expand_path('../spec_helper', __FILE__)

require 'asir'
require 'asir/transport/demux'

require 'asir/transport/buffer'

describe "ASIR::Transport::Demux" do
  attr_accessor :transport, :object

  before(:each) do
    self.transport = ASIR::Transport::Demux.new
    self.transport.transport_proc = lambda do | t, m |
      m.arguments[0].size % 2 == 0 ? t[:even] : t[:odd]
    end
    self.transport[:even] = ASIR::Transport::Buffer.new(:transport => ASIR::Transport::Local.new)
    self.transport[:even].pause!
    self.transport[:odd]  = ASIR::Transport::Buffer.new(:transport => ASIR::Transport::Local.new)
    self.transport[:odd].pause!
    self.object = ASIR::Test::TestObject.new(self)
    object.class.asir.transport = transport
  end

  it 'should direct even-sized arg[0] Arrays to transport[:even].' do
    result = object.asir.return_argument [ 1, 2 ]
    transport[:even].size.should == 1
    transport[:odd].size.should == 0
    result.should == nil
  end

  it 'should direct odd-sized arg[0] Arrays to transport[:odd].' do
    result = object.asir.return_argument [ 1, 2, 3 ]
    transport[:even].size.should == 0
    transport[:odd].size.should == 1
    result.should == nil
  end
end

