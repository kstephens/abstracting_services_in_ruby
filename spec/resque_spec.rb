require 'rubygems'
gem 'redis'
gem 'resque'
require 'asir'
require 'asir/transport/resque'
require 'asir/coder/marshal'
require 'timeout'

describe "ASIR::Transport::Resque" do
  it "should be able to start/stop redis" do
    with_cleanup! do
      create_transport!
      pid = Process.fork do
        # exec "false" # simulate failure to start.
        transport._start_conduit!
      end
      sleep 1
      Process.kill('TERM', pid)
      sleep 1
      wpid, status = nil, nil
      Timeout.timeout(5) do
        wpid, status = Process.waitpid2(pid, Process::WUNTRACED)
      end
      # puts status.inspect
      wpid.should == pid
      status.stopsig.should == nil
      status.termsig.should == nil
      status.exited?.should == true
      status.exitstatus.should == 0
      status.success?.should == true
    end
  end

  it "should process and stop! gracefully" do
    with_cleanup! do
      create_transport!
      start_conduit!; sleep 1
      start_client!

      message_count = 0
      transport.after_receive_message = lambda do | t, message |
        message_count += 1
        $stderr.write ">#{message_count}" if verbose
        if message_count >= 5
          t.stop!
        end
      end
      Timeout.timeout(20) do
        start_server!
      end

      message_count.should == 5
      exceptions.should == [ ]
    end
  end

  it "should bubble up Redis::CannotConnectError if redis is not running" do
    with_cleanup! do
      create_transport!
      message_count = 0
      lambda do
        transport.after_receive_message = lambda do | t, message |
          message_count += 1
          $stderr.write ">#{message_count}" if verbose
          if message_count >= 10
            t.stop!
          end
        end
        Timeout.timeout(20) do
          start_server!
        end
      end.should raise_error(Redis::CannotConnectError)
      message_count.should == 0
      exceptions.should == [ ]
    end
  end

  it "should bubble up dropped connection error" do
    with_cleanup! do
      create_transport!
      start_conduit!; sleep 1
      start_client!

      # Server should have errors.
      message_count = 0
      lambda do
        transport.after_receive_message = lambda do | t, message |
          message_count += 1
          $stderr.write ">#{message_count}" if verbose
          if message_count >= 5
            stop_client!
            stop_conduit! :signal => 9
          end
          if message_count >= 10
            t.stop!
          end
        end
        Timeout.timeout(20) do
          start_server!
        end
        raise "start_server! exited"
      end.should raise_error(Redis::CannotConnectError)
      message_count.should == 5
      exceptions.should == [ ]
    end
  end

  attr_accessor :transport, :target, :exceptions, :verbose

  before :each do
    @target = ASIR::Test::ResqueTarget.new
    @exceptions = [ ]
    @verbose = (ENV['ASIR_TEST_VERBOSE'] || 0).to_i > 0
  end

  def with_cleanup!
    yield
  ensure
    stop_client!
    stop_server!
    stop_conduit!
  end

  def create_transport!
    @uri = "redis://localhost:23456"
    @transport = ASIR::Transport::Resque.new(:uri => @uri)
    transport.encoder = ASIR::Coder::Marshal.new
    if verbose
      transport._logger = $stderr
      transport._log_enabled = true
    end
    ASIR::Client::Proxy.config_callbacks[target.class] = lambda do | proxy |
      proxy.transport = transport
    end
  end

  def start_conduit!
    transport.verbose = 0
    transport.start_conduit!
    transport.verbose = 0
  end

  def stop_conduit! opts = nil
    transport.verbose = 0
    transport.stop_conduit! opts
    transport.verbose = 0
  end

  def start_client! &blk
    @client_pid = Process.fork do
      # transport.verbose = 3
      i = 0
      loop do
        i += 1
        $stderr.write "<#{i}" if verbose
        target.asir.eval! "2 + 2"
        sleep 0.25
      end
    end
  end

  def stop_client!
    if @client_pid
      Process.kill 9, @client_pid
    end
  ensure
    @client_pid = nil
  end

  def start_server!
    transport.verbose = 0
    transport.prepare_server!
    transport.on_exception = lambda do | t, exc, kind, message, result |
      @exceptions << exc
      $stderr.puts "  on_exception: #{kind.inspect}: #{exc.inspect}\n  #{exc.backtrace * "\n  "}"
    end
    transport.throttle = {
      :min_sleep => 0.01,
      :max_sleep => 2,
      :inc_sleep => 0.1,
      :mul_sleep => 1.25,
      # :verbose => true,
    }
    transport.run_server!
    transport.verbose = 0
  end

  def stop_server!
    transport.stop!
  end
end

module ASIR
  module Test
    class TestError < ::Exception; end
    class ResqueTarget
      include ASIR::Client
      def raise_error! msg
        raise TestError, msg
      end
      def eval! expr
        result = eval expr
        # $stderr.puts "  #{self} eval!(#{expr.inspect}) => #{result.inspect}"
        result
      end
    end
  end
end


