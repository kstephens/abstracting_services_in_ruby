$: << File.expand_path('../../../lib', __FILE__)
$: << File.expand_path('../../lib', __FILE__)
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
      xml = @enc.encode(x)
      xml.should == "<#{x.class.name} />"
      @dec.decode(xml).should == x
    end
  end

  [
   1234,
   1.234,
   :symbol,
  ].each do | x |
    basic_objs << x
    it "should handle #{x.inspect}" do
      xml = @enc.encode(x)
      xml.should == "<#{x.class.name} >#{x.to_s}</#{x.class.name}>"
      @dec.decode(xml).should == x
    end
  end

  [
   'String',
  ].each do | x |
    basic_objs << x
    it "should handle #{x.inspect}" do
      xml = @enc.encode(x)
      xml.should == "<#{x.class.name} id=\"#{x.object_id}\" >#{x.to_s}</#{x.class.name}>"
      @dec.decode(xml).should == x
    end
  end

  it "should handle empty Array" do
    x = [ ]
    xml = @enc.encode(x)
    xml.should == "<#{x.class.name} id=\"#{x.object_id}\" ></#{x.class.name}>"
    @dec.decode(xml).should == x
  end

  it "should handle Array" do
    x = [ *basic_objs ]
    xml = @enc.encode(x)
    xml.should =~ %r{\A<#{x.class.name} id=\"#{x.object_id}\" ><NilClass /><TrueClass /><FalseClass /><Fixnum >1234</Fixnum><Float >1.234</Float><Symbol >symbol</Symbol><String id=\"[^"]+\" >String</String></#{x.class.name}>\Z} # " emacs
    @dec.decode(xml).should == x
  end

  it "should handle empty Hash" do
    x = { }
    xml = @enc.encode(x)
    xml.should == "<#{x.class.name} id=\"#{x.object_id}\" ></#{x.class.name}>"
    @dec.decode(xml).should == x
  end

  it "should handle Hash" do
    x = Hash[ *basic_objs.map{|e| e.inspect}.zip(basic_objs).flatten ]
    xml = @enc.encode(x)
    xml.should =~ %r{<#{x.class.name} id=\"#{x.object_id}\" >}
    xml.should =~ %r{</#{x.class.name}>}
    basic_objs.each do | v |
      vx = @enc.dup.encode(v)
      xml.should =~ %r{#{vx}}
      xml.should =~ %r{ >#{v.inspect}</String>}
    end
    @dec.decode(xml).should == x
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
    xml = @enc.encode(x)
    xml.should =~ %r{<#{x.class.name.gsub('::', '.')} id=\"#{x.object_id}\" >}
    xml.should =~ %r{</#{x.class.name.gsub('::', '.')}>}
    y = @dec.decode(xml)
    y.a.should == x.a
    y.h.should == x.h
    y.o.class.should == ASIR::Coder::XML::Test
    y.o.a.should == x.o.a
    x.instance_variables.sort { |a, b| a.to_s <=> b.to_s}.should == 
      y.instance_variables.sort { | a, b | a.to_s <=> b.to_s }
  end
end
