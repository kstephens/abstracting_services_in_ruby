require File.expand_path('../spec_helper', __FILE__)

$:.unshift File.expand_path('../../example', __FILE__)

describe "ASIR Example" do
  attr_accessor :file, :expects

  before(:each) do
    @expects = [ ]
  end

  after(:each) do
    @file.should_not == nil
    File.open(@file) do | fh |
      until fh.eof?
        line = fh.readline
        line.chomp!
        case
        when line.sub!(/^\s*#\s*EXPECT\/:\s*/, '')
          expect Regexp.new(line)
        when line.sub!(/^\s*#\s*EXPECT!\/:\s*/, '')
          expect Regexp.new(line), :'!~'
        when line.sub!(/^\s*#\s*EXPECT:\s*/, '')
          expect Regexp.new(Regexp.escape(line))
        when line.sub!(/^\s*#\s*EXPECT!:\s*/, '')
          expect Regexp.new(Regexp.escape(line)), :'!~'
        end
      end
    end
    @output, @exit_code = run_file!(@file)
    @exit_code.should == 0
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

  def run_file! file, output = StringIO.new('')
    progname_save, stdout_save, stderr_save = $0, $stdout, $stderr
    exc = system_exit = nil; exit_code = 0
    begin
      if true
        cmd = "ASIR_EXAMPLE_SILENT=1 ruby -I example -I lib #{file}"
        $stderr.puts "\n   Running #{cmd}:" if ENV['SPEC_VERBOSE']
        output = `#{cmd} 2>&1 | tee #{file}.out`
      else
        $stderr.puts "\n   Loading #{file}:" if ENV['SPEC_VERBOSE']
        $stdout.puts "*** #{$$}: client process"; $stdout.flush
        $stdout = $stderr = output
        $0 = file
        Kernel.load(file, true)
        output = output.string if StringIO === output
      end
    rescue ::SystemExit => system_exit
      exit_code = 1 # ???
    rescue ::Exception => exc
      exit_code = -1
    end
    [ output, exit_code ]
  ensure
    $0, $stdout, $stderr = progname_save, stdout_save, stderr_save
    $stderr.write output  if ENV['SPEC_VERBOSE']
    if exc
      stderr_save.puts "ERROR: #{file}: #{exc.inspect}\n#{exc.backtrace * "\n"}"
      raise exc
    end
  end

  def expect rx, mode = :'=~'
    @expects << [ rx, mode ]
  end

  Dir['example/**/ex[0-9]*.rb'].sort.each do | file |
    title = File.open(file) { | fh | fh.read(4096) }
    title = title =~ /#\s+!SLIDE[^\n]*\n\s*#\s*([^\n]+)/ && $1
    it "#{file} - #{title}" do
      @file = file
    end
  end
end
