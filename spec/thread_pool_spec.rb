require 'asir/thread_pool'

describe 'ASIR::ThreadPool' do
  it "should spawn workers only as needed" do
    tp.workers.size.should == 0
    work = tp.new do
      $stderr.puts "#{Thread.current} start" if @verbose
      sleep 2
      $stderr.puts "#{Thread.current} stop" if @verbose
    end
    tp.workers.size.should == 0
    work.class.should == ASIR::ThreadPool::Work
    tp.start_workers!
    sleep 0.25
    tp.workers.size.should == 1
    worker = tp.workers.first
    worker.class.should == ASIR::ThreadPool::Worker
    worker.work.should == work
    work.worker.should == worker
  end

  it "should spawn up to n_workers only" do
    # tp.verbose = 1
    works = [ ]
    20.times do
      works << tp.new do
        $stderr.puts "#{Thread.current} start" if @verbose
        sleep 0.2
        $stderr.puts "#{Thread.current} stop" if @verbose
      end
    end
    tp.start_workers!
    sleep 0.25
    tp.workers.size.should == n_workers
    tp.stop!
    tp.join
    tp.workers.size.should == 0
    works.each do | work |
      work.started.should == true
      work.finished.should == true
    end
  end

  def n_workers
    @n_workers ||= 10
  end

  def tp
    @tp ||= ASIR::ThreadPool.new(:n_workers => n_workers)
  end

  after :each do
    if @tp
      @tp.kill! rescue nil
    end
  end
end
