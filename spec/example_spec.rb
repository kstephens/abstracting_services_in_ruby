describe "ASIR Example" do
  attr_accessor :file, :expects

  before(:each) do
    @expects = [ ]
  end

  after(:each) do
    @file.should_not == nil
    cmd = "ASIR_EXAMPLE_SILENT=1 ruby -I example -I lib #{@file}"
    File.open(@file) do | fh |
      until fh.eof?
        line = fh.readline
        line.chomp!
        if line.sub!(/^\s*#\s*EXPECT:\s*/, '')
          expect Regexp.new(Regexp.escape(line))
        end
        if line.sub!(/^\s*#\s*EXPECT!:\s*/, '')
          expect Regexp.new(Regexp.escape(line)), :'!~'
        end
      end
    end

    $stderr.puts "\n   Running #{cmd}:" if ENV['SPEC_VERBOSE']
    @output = `#{cmd} 2>&1`
    $stderr.write @output  if ENV['SPEC_VERBOSE']
    @expects.empty?.should_not == true
    @expects.each do | rx, mode |
      $stderr.puts "    Checking #{mode} #{rx.inspect}" if ENV['SPEC_VERBOSE']
      case mode
      when :'=~'
        @output.should =~ rx
      when :'!~'
        @output.should_not =~ rx
      else
        raise ArgumentError
      end
    end
  end

  def expect rx, mode = :'=~'
    @expects << [ rx, mode ]
  end

  Dir['example/**/ex[0-9]*.rb'].sort.each do | file |
    it "#{file}" do
      @file = file
    end
  end
end
