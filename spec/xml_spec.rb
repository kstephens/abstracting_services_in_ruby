require File.expand_path('../spec_helper', __FILE__)
require 'asir/coder/xml'

describe "ASIR::Coder::XML" do
  before(:each) do 
    @enc = ASIR::Coder::XML.new
    @dec = @enc.dup
  end

  basic_objs = [ ]

  [
   nil,
   true,
   false,
  ].each do | x |
    basic_objs << x
    it "should handle #{x.inspect}" do
      xml = @enc.prepare.encode(x)
      xml.should == "<#{x.class.name} />"
      @dec.prepare.decode(xml).should == x
    end
  end

  [
   1234,
   1.234,
  ].each do | x |
    basic_objs << x
    it "should handle #{x.inspect}" do
      xml = @enc.prepare.encode(x)
      xml.should == "<#{x.class.name} v=\"#{x.to_s}\" />"
      @dec.prepare.decode(xml).should == x
    end
  end

  [
   :symbol,
  ].each do | x |
    basic_objs << x
    it "should handle #{x.inspect}" do
      xml = @enc.prepare.encode(x)
      xml.should == "<#{x.class.name} >#{x.to_s}</#{x.class.name}>"
      @dec.prepare.decode(xml).should == x
    end
  end

  [
   'String',
  ].each do | x |
    basic_objs << x
    it "should handle #{x.inspect}" do
      xml = @enc.prepare.encode(x)
      xml.should == "<#{x.class.name} id=\"1\" >#{x.to_s}</#{x.class.name}>"
      @dec.prepare.decode(xml).should == x
    end
  end

  it "should handle empty Array" do
    x = [ ]
    xml = @enc.prepare.encode(x)
    xml.should == "<#{x.class.name} id=\"1\" ></#{x.class.name}>"
    @dec.prepare.decode(xml).should == x
  end

  it "should handle Array" do
    x = [ *basic_objs ]
    xml = @enc.prepare.encode(x)
    xml.should =~ %r{\A<#{x.class.name} id=\"1\" ><NilClass /><TrueClass /><FalseClass /><Fixnum v="1234" /><Float v="1.234" /><Symbol >symbol</Symbol><String id=\"[^"]+\" >String</String></#{x.class.name}>\Z} # " emacs
    @dec.prepare.decode(xml).should == x
  end

  it "should handle empty Hash" do
    x = { }
    xml = @enc.prepare.encode(x)
    xml.should == "<#{x.class.name} id=\"1\" ></#{x.class.name}>"
    @dec.prepare.decode(xml).should == x
  end

  it "should handle Hash" do
    x = Hash[ *basic_objs.map{|e| e.inspect}.zip(basic_objs).flatten ]
    xml = @enc.prepare.encode(x)
    xml.should =~ %r{\A<#{x.class.name} id=\"1\" >}
    xml.should =~ %r{</#{x.class.name}>\Z}
    basic_objs.each do | v |
      vx = @enc.dup.encode(v)
      vx = vx.gsub(/id="[^"]+"/, 'id="\d+"')
      xml.should =~ Regexp.new(vx)
      xml.should =~ %r{ >#{v.inspect}</String>}
    end
    @dec.prepare.decode(xml).should == x
  end

  class ASIR::Coder::XML::Test
    attr_accessor :a, :h, :o
  end

  it "should handle deep objects" do
    x = ASIR::Coder::XML::Test.new
    x.a = [ *basic_objs ]
    x.h = Hash[ *basic_objs.map{|e| e.inspect}.zip(basic_objs).flatten ]
    x.o = ASIR::Coder::XML::Test.new
    x.o.a = 123
    xml = @enc.prepare.encode(x)
    xml.should =~ %r{<#{x.class.name.gsub('::', '.')} id=\"1\" >}
    xml.should =~ %r{</#{x.class.name.gsub('::', '.')}>}
    y = @dec.prepare.decode(xml)
    y.a.should == x.a
    y.h.should == x.h
    y.o.class.should == ASIR::Coder::XML::Test
    y.o.a.should == x.o.a
    x.instance_variables.sort { |a, b| a.to_s <=> b.to_s}.should == 
      y.instance_variables.sort { | a, b | a.to_s <=> b.to_s }
  end

  it "should handle multiple references to same objects." do
    x = Hash[ *basic_objs.map{|e| e.inspect}.zip(basic_objs).flatten ]
    y = [ 1, 2 ]
    x = [ x, x, y, y ]
    xml = @enc.prepare.encode(x)
    y = @dec.prepare.decode(xml)
    y[0].object_id.should == y[1].object_id
    y[2].object_id.should == y[3].object_id
  end

  it "should handle self-referencing Array." do
    x = [ 1 ]
    x << x
    xml = @enc.prepare.encode(x)
    y = @dec.prepare.decode(xml)
    y[0].should == x[0]
    y[1].object_id.should == y.object_id
  end

  it "should handle self-referencing Hash." do
    x = { :a => 1 }
    x[:self] = x
    xml = @enc.prepare.encode(x)
    y = @dec.prepare.decode(xml)
    y[:a].should == x[:a]
    y[:self].object_id.should == y.object_id
  end

end
