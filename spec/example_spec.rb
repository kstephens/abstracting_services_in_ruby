require 'spec_helper'

$:.unshift File.expand_path('../../example', __FILE__)

require 'timeout'

class ASIR::Error::TestTimeout < ASIR::Error::Fatal; end

describe "ASIR Example" do
  attr_accessor :file, :expects

  before(:each) do
    @expects = [ ]
    @verbose = (ENV['SPEC_VERBOSE'] || 0).to_i
  end

  def file! file
    @file = file
    File.open(@file) do | fh |
      until fh.eof?
        line = fh.readline
        line.chomp!
        case
        when line.sub!(/^\s*#\s*PENDING:\s*/, '')
          line.strip!
          @pending_reason = line
          @pending = ! ! (eval(line) rescue nil)
          # $stderr.puts "  PENDING #{@pending_reason.inspect} => #{@pending.inspect}" if ENV['SPEC_VERBOSE']
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

    if @pending
      pending @pending_reason do
        check_result!
      end
    else
      check_result!
    end
  end

  def check_result!
    @exit_code.should == 0
    @expects.empty?.should_not == true
    @expects.each do | rx, mode |
      $stderr.puts "    Checking #{mode} #{rx.inspect}" if @verbose >= 2
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

  def run_file! file
    output = nil
    output_file = "#{file}.out"
    progname_save, stdout_save, stderr_save = $0, $stdout, $stderr
    ruby = ASIR.ruby_path
    exc = system_exit = nil; exit_code = 0
    begin
      Timeout.timeout(20, ASIR::Error::TestTimeout) do
        cmd = "ASIR_EXAMPLE_SILENT=1 #{ruby.inspect} -I example -I lib #{file}"
        if @verbose >= 1
          $stderr.puts "\n  Running #{cmd}:"
          $stderr.puts "\n    -- #{@title}" if @title
        end
        File.unlink(output_file) rescue nil
        system("#{cmd} >#{output_file} 2>&1")
      end
    rescue ASIR::Error::TestTimeout
      $stderr.puts "  Warning: Timeout in #{@file}"
      exit_code = 0 # OK if checks pass
    rescue ::SystemExit => system_exit
      exit_code = 1 # ???
    rescue ::Exception => exc
      exit_code = -1
    end
    output = File.read(output_file)
    [ output, exit_code ]
  ensure
    $0, $stdout, $stderr = progname_save, stdout_save, stderr_save
    output ||= File.read(output_file)
    $stderr.write output if @verbose >= 1
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
      @title = title
      file! file
    end
  end
end
