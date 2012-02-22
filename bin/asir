#!/usr/bin/env ruby
# -*- ruby -*-

require 'time'

$: << File.expand_path('../../lib', __FILE__)
require 'asir'

module ASIR
class Main
  attr_accessor :verb, :adjective, :object, :identifier
  attr_accessor :config_rb, :config
  attr_accessor :log_dir, :pid_dir

  attr_accessor :exit_code

  def initialize
    @verbose = 0
    @progname = File.basename($0)
    @log_dir = '/var/log'
    @log_dir = '/tmp' unless File.writable?(@log_dir)
    @pid_dir = '/var/run'
    @pid_dir = '/tmp' unless File.writable?(@pid_dir)
    @exit_code = 0
  end

  def parse_args! args = ARGV.dup
    @args = args
    @verb, @adjective, @object, @identifier = args.map{|x| x.to_sym}
    @identifier ||= :'0'
    self
  end
  
  def log_str
    "#{Time.now.gmtime.iso8601(4)} #{$$} #{log_str_no_time}"
  end

  def log_str_no_time
    "#{@progname} #{@verb} #{@adjective} #{@object} #{@identifier}"
  end

  def run!
    unless verb && adjective && object
      @exit_code = 1
      return usage!
    end
    config(:config)
    case verb
    when :restart
      @verb = :stop
      _run! && sleep(1)
      @verb = :start
      _run!
    else
      _run!
    end
    self
  end

  def _run!
    send(:"#{verb}_#{adjective}_#{object}!")
  rescue ::Exception => exc
    $stderr.puts "#{log_str} ERROR\n#{exc.inspect}\n  #{exc.backtrace * "\n  "}"
    @exit_code += 1
    nil
  end

  def method_missing sel, *args
    case sel.to_s
    when /^start_([^_]+)_worker!$/
      _start_worker!
    when /^status_([^_]+)_([^_]+)!$/
      pid = server_pid
      puts "#{log_str} pid #{pid}"
      system("ps -fw -p #{pid}")
    when /^log_([^_]+)_([^_]+)!$/
      puts log_file
    when /^taillog_([^_]+)_([^_]+)!$/
      exec "tail -f #{log_file.inspect}"
    when /^pid_([^_]+)_([^_]+)!$/
      puts "#{pid_file} #{File.read(pid_file) rescue nil}"
    when /^stop_([^_]+)_([^_]+)!$/
      kill_server!
    else
      super
    end
  end

  def usage!
    $stderr.puts <<"END"
SYNOPSIS:
  asir <<verb>> <<adjective>> <<object>> [ <<identifier>> ]

VERBS:
  start
  stop
  restart
  status
  log
  pid

ADJECTIVE-OBJECTs:
  beanstalk conduit
  beanstalk worker
  zmq worker
  webrick worker

EXAMPLES:

  export ASIR_CONFIG_RB="some_system/asir_config.rb"
  asir start beanstalk conduit
  asir status beanstalk conduit

  asir start webrick worker

  asir start beanstalk worker 1
  asir start beanstalk worker 2

  asir start zmq worker
  asir start zmq worker 1
  asir start zmq worker 2
END
  end

  def start_beanstalk_conduit!
    fork_server! "beanstalkd"
  end

  def _start_worker! type = adjective
    type = type.to_s
    fork_server! do
      require "asir/transport/#{type}"
      _create_transport ASIR::Transport.const_get(type[0..0].upcase + type[1..-1])
      _run_workers!
    end
  end

  ################################################################

  def config_rb
    @config_rb ||=
      File.expand_path(ENV['ASIR_CONFIG_RB'] || 'config/asir_config.rb')
  end

  def config_lambda
    @config_lambda ||=
      begin
        file = config_rb
        $stderr.puts "#{log_str} loading #{file} ..." if @verbose >= 1
        expr = File.read(file)
        expr = "begin; lambda do | asir |; #{expr}\n end; end"
        cfg = Object.new.send(:eval, expr, binding, file, 1)
        # cfg = load file
        # $stderr.puts "#{log_str} loading #{file} DONE" if @verbose >= 1
        raise "#{file} did not return a Proc, returned a #{cfg.class}" unless Proc === cfg
        cfg
      end
  end

  def config verb = @verb
    (@config ||= { })[verb] ||=
      begin
        save_verb = @verb
        @verb = verb
        $stderr.puts "#{log_str} calling #{config_rb} asir.verb=#{@verb.inspect} ..." if @verbose >= 1
        cfg = config_lambda.call(self)
        $stderr.puts "#{log_str} calling #{config_rb} asir.verb=#{@verb.inspect} DONE" if @verbose >= 1
        cfg
      ensure
        @verb = save_verb
      end
  end

  def pid_file
    "#{pid_dir}/#{asir_basename}.pid"
  end

  def log_file
    "#{log_dir}/#{asir_basename}.log"
  end

  def asir_basename
    "asir-#{adjective}-#{object}-#{identifier}"
  end

  def fork_server! cmd = nil, &blk
    pid = Process.fork do
      run_server! cmd, &blk
    end
    Process.detach(pid) # Forks a Thread?  We are gonna exit anyway.
    File.open(pid_file, "w+") { | o | o.puts pid }
    File.chmod(0666, pid_file) rescue nil
    self
  end

  def run_server! cmd = nil
    log = File.open(log_file, "a+")
    File.chmod(0666, log_file) rescue nil
    log.puts "#{log_str} starting pid #{$$}"
    $stdin.close rescue nil
    STDIN.close rescue nil
    STDOUT.reopen(log)
    STDERR.reopen(log)
    Process.daemon rescue nil # Ruby 1.9.x only.
    if cmd
      exec(cmd)
    else
      begin
        yield
      ensure
        log.puts "#{log_str} finished pid #{$$}"
        File.unlink(pid_file) rescue nil
      end
    end
  rescue ::Exception => exc
    msg = "#{log_str} ERROR pid #{$$}\n#{exc.inspect}\n  #{exc.backtrace * "\n  "}"
    $stderr.puts msg
    log.puts msg
    raise
  end

  def kill_server!
    log = nil
    log = File.open(log_file, "a+")
    log.puts "#{log_str} kill"
    pid = server_pid
    log.puts "#{log_str} kill pid #{pid}"
    begin
      Process.kill('TERM', pid)
      if @force
        sleep 5
        Process.kill('KILL', pid) rescue nil
      end
    end
  rescue ::Exception => exc
    log.puts "#{log_str} ERROR\n#{exc.inspect}\n  #{exc.backtrace * "\n  "}"
    raise
  ensure
    log.close if log
  end

  def log msg
    File.open(log_file, "a+") do | log |
      log.puts "#{log_str} #{msg}"
    end
  end

  def server_pid
    pid = File.read(pid_file).chomp!
    pid.to_i
  end

  def _create_transport default_class
    config(:environment)
    case transport = config(:start)
    when default_class
      @transport = transport
    else
      raise "Expected config to return a #{default_class}, not a #{transport.class}"
    end
  end

  def worker_pids
    (@worker_pids ||= { })[@adjective] ||= { }
  end

  def _run_workers!
    $0 = "#{@progname} #{@adjective} #{@object} #{@identifier}"

    worker_id = 0
    @transport.prepare_server!
    worker_processes = @transport[:worker_processes] || 1
    (worker_processes - 1).times do
      wid = worker_id += 1
      pid = Process.fork do
        _run_transport_server! wid
      end
      Process.setgprp(pid, 0) rescue nil
      worker_pids[wid] = pid
      log "forked #{wid} pid #{pid}"
    end

    _run_transport_server!
  ensure
    log "worker 0 stopped"
    _stop_workers!
  end

  def _run_transport_server! wid = 0
    $0 += " #{wid}"
    old_arg0 = $0.dup
    after_receive_message = @transport.after_receive_message || lambda { | transport, message | nil }
    @transport.after_receive_message = lambda do | transport, message |
      $0 = "#{old_arg0} #{transport.message_count} #{message.identifier}"
      after_receive_message.call(transport, message)
    end
    @transport.run_server!
    self
  end

  def _stop_workers!
    workers = worker_pids.dup
    worker_pids.clear
    workers.each do | wid, pid |
      log "stopping #{wid} pid #{pid}"
      Process.kill('TERM', pid) rescue nil
      if @force
        sleep 1
        Process.kill('KILL', pid) rescue nil
      end
    end
    workers.each do | wid, pid |
      wr = Process.waitpid(pid) rescue nil
      log "stopped #{wid} pid #{pid} => #{wr.inspect}"
    end
  ensure
    worker_pids.clear
  end

end # class
end # module

exit ASIR::Main.new.parse_args!.run!.exit_code

