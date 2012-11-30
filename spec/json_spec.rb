require File.expand_path('../spec_helper', __FILE__)
require 'asir/coder/json'

describe "ASIR::Coder::JSON" do
  before(:each) do 
    @enc = ASIR::Coder::JSON.new
    @dec = @enc.dup
  end

  basic_objs = [ ]

  [
   [ nil, 'null' ],
   true,
   false,
  ].each do | x |
    x, str = *x
    str ||= x.inspect
    str = "[#{str}]"
    basic_objs << [ x, str ]
    it "should handle #{x.inspect}" do
      out = @enc.prepare.encode(x)
      out.should == str
      @dec.prepare.decode(out).should == x
    end
  end

  [
   1234,
   1.234,
   [ :symbol, '"symbol"' ],
  ].each do | x |
    x, str = *x
    str ||= x.inspect
    str = "[#{str}]"
    basic_objs << [ x, str ]
    it "should handle #{x.inspect}" do
      out = @enc.prepare.encode(x)
      out.should == str
      y = @dec.prepare.decode(out)
      y = y.to_sym if Symbol === x
      y.should == x
    end
  end

  [
   'String',
  ].each do | x |
    x, str = *x
    str ||= x.inspect
    str = "[#{str}]"
    basic_objs << [ x, str ]
    it "should handle #{x.inspect}" do
      out = @enc.prepare.encode(x)
      out.should == str
      y = @dec.prepare.decode(out)
      y.should == x
    end
  end

  it "should handle empty Array" do
    x = [ ]
    out = @enc.prepare.encode(x)
    out.should == "[[]]"
    @dec.prepare.decode(out).should == x
  end

  it "should handle Array" do
    x = basic_objs.map{|e| e[0]}
    out = @enc.encode(x)
    out.should == "[[null,true,false,1234,1.234,\"symbol\",\"String\"]]"
    y = @dec.decode(out)
    y.should == x.map{|e| Symbol === e ? e.to_s : e }
  end

  it "should handle empty Hash" do
    x = { }
    out = @enc.encode(x)
    out.should == "[{}]"
    @dec.decode(out).should == x
  end

  it "should handle Hash" do
    x = Hash[ *basic_objs.flatten.reverse ]
    out = @enc.prepare.encode(x)
    out.should =~ %r{\A\[\{}
    out.should =~ %r{\}\]\Z}
    basic_objs.each do | v, str |
      # out.should =~ %r{#{k.inspect}:}
      out.should =~ %r{#{str}}
    end
    y = @dec.prepare.decode(out)
    y.should == x.inject({}){|h, (k, v)| h[k] = Symbol === v ? v.to_s : v; h }
  end

  module ASIR::Coder::Test
    class Object
      attr_accessor :a, :h, :o
    end
  end

  it "should handle deep objects" do
    x = ASIR::Coder::Test::Object.new
    x.a = [ *basic_objs.map{|a| a[0]} ]
    x.h = Hash[ *basic_objs.flatten.reverse ]
    x.o = ASIR::Coder::Test::Object.new
    x.o.a = 123
    out = @enc.prepare.encode(x)
    if out =~ %r{#<ASIR::Coder::Test::Object}
      out.should =~ %r{\A\[\"#<ASIR::Coder::Test::Object:[^>]+>\"\]\Z}
    else
      out.should =~ %r{"a":\[null,true,false,1234,1.234,"symbol","String"\]}
      out.should =~ %r{"h":\{}
      out.should =~ %r{"\[1234\]":1234}
      out.should =~ %r{"\[1.234\]":1.234}
      out.should =~ %r{"\[null\]":null}
      out.should =~ %r{"\[\\"String\\"\]":"String"}
      out.should =~ %r{"\[\\"symbol\\"\]":"symbol"}
      out.should =~ %r{"\[null\]":null}
      out.should =~ %r{"\[true\]":true}
      out.should =~ %r{"\[null\]":null}
    end

    # FIXME:
    #out.should =~ %r{<#{x.class.name.gsub('::', '.')} id=\"#{x.object_id}\" >}
    #out.should =~ %r{</#{x.class.name.gsub('::', '.')}>}
    y = @dec.prepare.decode(out)
    (String === y).should == true
=begin
FIXME:
    y.a.should == x.a
    y.h.should == x.h
    y.o.class.should == ASIR::Coder::Test::Object
    y.o.a.should == x.o.a
    x.instance_variables.sort { | a, b | a.to_s <=> b.to_s }.should == 
      y.instance_variables.sort { | a, b | a.to_s <=> b.to_s }
=end
  end
end

