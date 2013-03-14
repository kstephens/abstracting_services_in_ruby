require File.expand_path('../spec_helper', __FILE__)
require 'asir/coder/yaml'

describe "ASIR::Coder::Yaml" do
  before(:each) do
    @enc = ASIR::Coder::Yaml.new
    @dec = @enc.dup
  end

  basic_objs = [ ]

  [
    [ nil, '' ],
    true,
    false,
    123,
    123.45,
    'String',
    [ :Symbol, ':Symbol' ],
  ].each do | x |
    x, str = *x
    if x == nil
    end
    str ||= x.to_s
    unless x == nil and RUBY_VERSION !~ /^1\.8/ and RUBY_ENGINE =~ /jruby/i
      str = " #{str}"
    end
    basic_objs << [ x, str ]
    it "should handle #{x.inspect}" do
      out = @enc.prepare.encode(x)
      out.should =~ /\A---#{str} ?\n(\.\.\.\n)?\Z/
      @dec.prepare.decode(out).should == x
    end
  end

  it 'should handle :never_binary.' do
    @enc.yaml_options = { :never_binary => true }
    out = do_message
    out.should =~ /^  :ascii_8bit: hostname/m
    case RUBY_VERSION
    when /^1\.8/
      out.should =~ /^  :binary: !binary /m
    when '1.9.2'
      out.should =~ /^  :binary: |-\n/m
    else
      out.should =~ /^  :binary: (! )?"\\x04/m
    end
  end

  it 'should handle :ASCII_8BIT_ok.' do
    @enc.yaml_options = { :ASCII_8BIT_ok => true }
    out = do_message
    out.should =~ /^  :ascii_8bit: hostname/m
    out.should =~ /^  :binary: !binary /m
  end

  def do_message
    rcvr = "String"
    sel = :eval
    args = [ "2 + 2" ]
    msg = ASIR::Message.new(rcvr, sel, args, nil, nil)
    str = 'hostname'
    if str.respond_to?(:force_encoding)
      str = str.force_encoding("ASCII-8BIT")
    end
    msg[:ascii_8bit] = str
    str = Marshal.dump(@dec)
    if str.respond_to?(:encoding)
      str.encoding.inspect.should == "#<Encoding:ASCII-8BIT>"
    end
    msg[:binary] = str
    msg[:source_backtrace] = caller
    out = @enc.prepare.encode(msg)
  end

  if ''.methods.include?(:force_encoding)
    it 'should extend Psych with :never_binary option.' do
      require 'socket'
      hostname = Socket.gethostname
      enc = hostname.encoding
      if enc.inspect != "#<Encoding:ASCII-8BIT>" # JRUBY?
        hostname.force_encoding('ASCII-8BIT')
        enc = hostname.encoding
      end
      enc.inspect.should == "#<Encoding:ASCII-8BIT>"

      str = enc.inspect
      str.force_encoding(hostname.encoding)
      str.encoding.inspect.should == "#<Encoding:ASCII-8BIT>"

      yaml = ::YAML.dump(str)
      case RUBY_VERSION
      when '1.9.2'
        yaml.should == "--- \"#<Encoding:ASCII-8BIT>\"\n"
      else
        yaml.should == "--- !binary |-\n  IzxFbmNvZGluZzpBU0NJSS04QklUPg==\n"
      end

      case RUBY_VERSION
      when '1.9.2'
        yaml = ::YAML.dump(str)
      else
        yaml = ::YAML.dump(str, nil, :never_binary => true)
      end
      yaml.should =~ /\A--- (! )?['"]\#<Encoding:ASCII-8BIT>['"]\n/
    end

    it 'should handle :never_binary options.' do
      str = '8bitascii'.force_encoding('ASCII-8BIT')

      @enc.yaml_options = @dec.yaml_options = nil
      out = @enc.prepare.encode(str)
      case RUBY_VERSION
      when '1.9.2'
        case RUBY_ENGINE
        when /jruby/i
          out.should == "--- 8bitascii\n"
        else
          out.should == "--- 8bitascii\n"
        end
      else
        out.should == "--- !binary |-\n  OGJpdGFzY2lp\n"
      end
      @dec.prepare.decode(str).should == str

      @enc.yaml_options = { :never_binary => true }
      @dec.yaml_options = @enc.yaml_options
      out = @enc.prepare.encode(str)
      case RUBY_ENGINE
      when /jruby/i
        out.should == "--- 8bitascii\n"
      else
        out.should == "--- 8bitascii\n"
      end
      inp = @dec.prepare.decode(str)
      inp.should == str
      inp.encoding.inspect.should == "#<Encoding:UTF-8>"
    end
  end
end

