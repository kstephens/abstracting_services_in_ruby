require 'asir/initialization'
require 'asir/additional_data'
require 'thread'
require "time"

module ASIR
  class ThreadPool
    include Initialization, AdditionalData
    attr_accessor :thread_class, :workers, :n_workers
    attr_accessor :auto_start_workers
    attr_accessor :work_queue
    attr_accessor :verbose
    attr_accessor :run

    def initialize *args
      super
      @thread_class ||= ::Thread
      @workers_mutex  = Mutex.new
      @work_mutex     = Mutex.new
      @workers      ||= [ ]
      @work_queue   ||= Queue.new
      @run = false
      @work_id = @worker_id = 0
      @time_0 ||= Time.now
    end

    # Returns a new Work object.
    def new &blk
      work_id = @work_mutex.synchronize do
        @work_id += 1
      end
      work = Work.new(:block => blk, :work_id => work_id)
      work_created! work
      @work_queue.enq(work)
      @run = true
      start_workers! if @auto_start_workers
      work
    end

    # Keep a list of workers busy.
    def start_workers!
      return nil unless @run
      workers_size = @workers.size
      want_n = [ n_workers, @work_queue.size ].min
      want_n = n_workers if want_n > n_workers
      start_n = want_n - workers_size
      start_n = 0 if start_n < 0
      return unless start_n > 0
      log! { "start_workers! #{start_n}" }
      start_n.times do
        start_worker!
      end
      self
    end

    def start_worker!
      worker = nil
      thread_class.new do
        worker_id = @workers_mutex.synchronize do
          @worker_id += 1
        end
        worker = Worker.new(:thread_pool => self, :worker_id => worker_id)
        worker_created! worker
        begin
          worker_starting! worker
          @workers_mutex.synchronize do
            @workers << worker
          end
          worker.run!
        ensure
          @workers_mutex.synchronize do
            @workers.delete(worker)
          end
          worker_stopping! worker
        end
      end
      worker
    end

    def worker_created! worker
      log! { "worker_created! #{worker.inspect}" }
    end

    def worker_starting! worker
      log! { "worker_starting! #{worker}" }
    end

    def worker_stopping! worker
      log! { "worker_stopping! #{worker}" }
    end

    def work_created! work
      log! { "work_created! #{work.inspect}" }
    end

    def work_starting! work
      log! { "work_starting! #{work.inspect} #{work.worker.inspect}" }
    end

    def work_stopping! work
      log! { "work_stopping! #{work.inspect}" }
    end

    def log! msg = nil
      return unless @verbose
      msg ||= yield
      @time_1 = Time.now
      $stderr.puts "  #{@time_1 - @time_0} #{$$} #{Thread.current.object_id} #{self} #{msg}"
      self
    end

    def stop!
      log! :stop!
      @run = false
      # Ask each current worker to :stop!
      @workers_mutex.synchronize do
        @workers.dup.each do | w |
          @work_queue.enq :stop!
        end
      end
      # Just incase.
      @work_queue.enq :stop!
      self
    end

    def kill! *args
      log! :kill!
      @run = false
      @workers_mutex.synchronize do
        @workers.dup.each do | worker |
          worker.kill! *args
        end
      end
      self
    end

    def join *args
      until @workers.empty?
        @workers.dup.each do | worker |
          worker && worker.join(*args)
        end
      end
    end

    class Work
      include Initialization, AdditionalData
      attr_accessor :work_id, :block, :thread, :worker
      attr_accessor :started, :finished

      def to_s; super.sub(/>$/, " #{@work_id}>"); end
      def inspect; to_s; end

      def run!
        @thread = ::Thread.current
        thread_pool.work_starting! self
        @started = true
        @block.call
        @finished = true
      ensure
        @thread = nil
        thread_pool.work_stopping! self
      end
      def thread_pool; @worker.thread_pool; end
    end

    class Worker
      include Initialization, AdditionalData
      attr_accessor :thread_pool, :worker_id
      # Current Work and Thread.
      attr_accessor :work, :thread
      attr_accessor :run, :running, :stopping, :stopped

      def to_s; super.sub(/>$/, " #{@worker_id} #{@work_inspect}>"); end
      def inspect; to_s; end

      def run!
        @thread = Thread.current
        @run = @running = true
        while @run
          work = thread_pool.work_queue.deq
          if work == :stop!
            @run = false
            @stopping = true
            break
          end
          begin
            @work = work
            work.worker = self
            work.run!
          ensure
            work.thread = work.worker = nil
            @work = nil
          end
        end
      ensure
        if @stopping
          @stopped = true
        end
        @running = false
        @thread = nil
      end

      def join *args
        @run = false
        @thread.join(*args) if @thread
      end

      def stop!
        @stopping = true
        @run = false
        self
      end

      def kill! *args
        stop!
        @thread.raise(*args) if @thread
        self
      end

    end
  end
end
