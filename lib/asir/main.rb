require 'asir'
require 'asir/environment'
require 'time'

module ASIR
class Main
  attr_accessor :env, :args, :exit_code
  # Delegate getter/setters to @env.
  [ :verb, :adjective, :object, :identifier,
    :config_rb,
    :verbose,
    :options,
    :log_dir, :log_file,
    :pid_dir, :pid_file,
  ].
    map{|g| [ g, :"#{g}=" ]}.
    flatten.each do | m |
      define_method(m) { | *args | @env.send(m, *args) }
    end
  attr_accessor :progname
  # Options:
  attr_accessor :force

  # Transport selected from asir.phase = :transport.
  attr_accessor :transport

  def initialize
    self.env = ASIR::Environment.new
    self.progname = File.basename($0)
    self.exit_code = 0
  end

  def parse_args! args = ARGV.dup
    self.args = args
    until args.empty?
      case args.first
      when /^--?h(elp)/
        @help = true
        return self
      when /^([a-z0-9_]+=)(.*)/i
        k, v = $1.to_sym, $2
        args.shift
        v = v.to_i if v == v.to_i.to_s
        send(k, v)
      else
        break
      end
    end
    self.verb, self.adjective, self.object, self.identifier = args.map{|x| x.to_sym}
    self.identifier ||= :'0'
    self
  end

  def config! *args
    @env.config! *args
  end

  def log_str
    "#{Time.now.gmtime.iso8601(4)} #{$$} #{log_str_no_time}"
  end

  def log_str_no_time
    "#{progname} #{verb} #{adjective} #{object} #{identifier}"
  end

  def run!
    if @help
      return usage!
    end
    unless verb && adjective && object
      self.exit_code = 1
      return usage!
    end
    config!(:configure)
    # $stderr.puts "log_file = #{log_file.inspect}"
    case self.verb
    when :restart
      self.verb = :stop
      _run_verb! && sleep(1)
      self.verb = :start
      _run_verb!
    else
      _run_verb!
    end
    self
  rescue ::Exception => exc
    $stderr.puts "#{log_str} ERROR\n#{exc.inspect}\n  #{exc.backtrace * "\n  "}"
    self.exit_code += 1
    self
  end

  def _run_verb!
    sel = :"#{verb}_#{adjective}_#{object}!"
    if verbose >= 3
      $stderr.puts "  verb      = #{verb.inspect}"
      $stderr.puts "  adjective = #{adjective.inspect}"
      $stderr.puts "  object    = #{object.inspect}"
      $stderr.puts "  sel       = #{sel.inspect}"
    end
    send(sel)
  rescue ::Exception => exc
    $stderr.puts "#{log_str} ERROR\n#{exc.inspect}\n  #{exc.backtrace * "\n  "}"
    self.exit_code += 1
    raise
    nil
  end

  def method_missing sel, *args
    log "method_missing #{sel}" if verbose >= 3
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
      pid = _alive?
      puts "#{pid_file} #{pid || :NA} #{alive}"
    when /^alive_([^_]+)_([^_]+)!$/
      pid = _alive?
      puts "#{pid_file} #{pid || :NA} #{alive}" if @verbose
      self.exit_code += 1 unless alive
    when /^stop_([^_]+)_([^_]+)!$/
      kill_server!
    else
      super
    end
  end

  def _alive?
    pid = server_pid rescue nil
    process_running? pid
  end

  def usage!
    $stderr.puts <<"END"
SYNOPSIS:
  asir [ <<options>> ... ] <<verb>> <<adjective>> <<object>> [ <<identifier>> ]

OPTIONS:
  config_rb=file.rb ($ASIR_LOG_DIR)
  pid_dir=dir/      ($ASIR_PID_DIR)
  log_dir=dir/      ($ASIR_LOG_DIR)
  verbose=[0-9]

VERBS:
  start
  stop
  restart
  status
  log
  pid
  alive

ADJECTIVE-OBJECTs:
  beanstalk conduit
  beanstalk worker
  zmq worker
  webrick worker
  resque conduit
  resque worker

EXAMPLES:

  export ASIR_CONFIG_RB="some_system/asir_config.rb"
  asir start beanstalk conduit
  asir status beanstalk conduit

  asir start webrick worker
  asir pid   webrick worker

  asir start beanstalk worker 1
  asir start beanstalk worker 2

  asir start zmq worker
  asir start zmq worker 1
  asir start zmq worker 2
END
    self
  end

  def start_beanstalk_conduit!
    _start_conduit!
  end

  def start_resque_conduit!
    _start_conduit!
  end

  def _start_conduit! type = adjective
    if (pid = _alive?) && ! force
      log "already-running pid #{pid}", :stderr
      return
    end
    log "start_conduit! #{type}"
    config!(:environment)
    self.transport = config!(:transport)
    fork_server! do
      transport.start_conduit! :fork => false
    end
  end

  def _start_worker! type = adjective
    if (pid = _alive?) && ! force
      log "already-running pid #{pid}", :stderr
      return
    end
    log "start_worker! #{type}"
    type = type.to_s
    config!(:environment)
    self.transport = config!(:transport)

    # Get the expected transport class.
    transport_file = "asir/transport/#{type}"
    log "loading #{transport_file}"
    require transport_file
    transport_class = ASIR::Transport.const_get(type[0..0].upcase + type[1..-1])

    fork_server! do
      _create_transport transport_class
      _run_workers!
    end
  end

  def fork_server! cmd = nil, &blk
    pid = Process.fork do
      run_server! cmd, &blk
    end
    log "forked pid #{pid}"
    Process.detach(pid) # Forks a Thread?  We are gonna exit anyway.
    File.open(pid_file, "w+") { | o | o.puts pid }
    File.chmod(0666, pid_file) rescue nil

    # Wait and check if process still exists.
    sleep 3
    unless process_running? pid
      raise "Server process #{pid} died to soon?"
    end

    self
  end

  def run_server! cmd = nil
    nf = File.open("/dev/null")
    nf.sync = true
    STDIN.reopen(nf)
    STDIN.sync = true
    $stdin.reopen(nf) if $stdin.object_id != STDIN.object_id
    $stdin.sync = true

    lf = File.open(log_file, "a+")
    lf.sync = true
    File.chmod(0666, log_file) rescue nil

    STDOUT.reopen(lf)
    STDOUT.sync = true
    $stdout.reopen(lf) if $stdout.object_id != STDOUT.object_id
    $stdout.sync = true
    STDERR.reopen(lf)
    STDERR.sync = true
    $stderr.reopen(lf) if $stderr.object_id != STDERR.object_id
    $stderr.sync = true

    # Process.daemon rescue nil # Ruby 1.9.x only.
    lf.puts "#{log_str} starting pid #{$$}"
    begin
      if cmd
        exec(cmd)
      else
        yield
      end
    ensure
      lf.puts "#{log_str} finished pid #{$$}"
      File.unlink(pid_file) rescue nil
    end
    self
  rescue ::Exception => exc
    msg = "ERROR pid #{$$}\n#{exc.inspect}\n  #{exc.backtrace * "\n  "}"
    log msg, :stderr
    raise
    self
  end

  def kill_server!
    log "#{log_str} kill"
    pid = server_pid
    stop_pid! pid
  rescue ::Exception => exc
    log "#{log_str} ERROR\n#{exc.inspect}\n  #{exc.backtrace * "\n  "}", :stderr
    raise
  end

  def log msg, to_stderr = false
    if to_stderr
      $stderr.puts "#{log_str_no_time} #{msg}" rescue nil
    end
    File.open(log_file, "a+") do | log |
      log.puts "#{log_str} #{msg}"
    end
  end

  def server_pid
    pid = File.read(pid_file).chomp!
    pid.to_i
  end

  def _create_transport default_class
    config!(:environment)
    case transport = config!(:transport)
    when default_class
      self.transport = transport
    else
      raise "Expected config to return a #{default_class}, not a #{transport.class}"
    end
  end

  def worker_pids
    (@worker_pids ||= { })[adjective] ||= { }
  end

  def _run_workers!
    $0 = "#{progname} #{adjective} #{object} #{identifier}"

    worker_id = 0
    transport.prepare_server!
    worker_processes = transport[:worker_processes] || 1
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
    log "running transport worker #{transport.class} #{wid}"
    config!(:start)
    $0 += " #{wid} #{transport.uri rescue nil}"
    old_arg0 = $0.dup
    after_receive_message = transport.after_receive_message || lambda { | transport, state | nil }
    transport.after_receive_message = lambda do | transport, state |
      message = state.message
      $0 = "#{old_arg0} #{transport.message_count} #{message.identifier}"
      after_receive_message.call(transport, message)
    end
    transport.run_server!
    self
  end

  def _stop_workers!
    workers = worker_pids.dup
    worker_pids.clear
    workers.each do | wid, pid |
      config!(:stop)
      stop_pid! pid, "wid #{wid} "
    end
    workers.each do | wid, pid |
      wr = Process.waitpid(pid) rescue nil
      log "stopped #{wid} pid #{pid} => #{wr.inspect}", :stderr
    end
  ensure
    worker_pids.clear
  end

  def stop_pid! pid, msg = nil
    log "stopping #{msg}pid #{pid}", :stderr
    if process_running? pid
      log "TERM pid #{pid}"
      Process.kill('TERM', pid) rescue nil
      sleep 3
      if force or process_running? pid
        log "KILL pid #{pid}", :stderr
        Process.kill('KILL', pid) rescue nil
      end
      if process_running? pid
        log "cant-stop pid #{pid}", :stderr
      end
    else
      log "not-running? pid #{pid}", :stderr
    end
  end

  def process_running? pid
    case pid
    when false, nil
    when Integer
      Process.kill(0, pid)
    else
      raise TypeError, "expected false, nil, Integer; given #{pid.inspect}"
    end
    pid
  rescue ::Errno::ESRCH
    false
  rescue ::Exception => exc
    $stderr.puts "  DEBUG: process_running? #{pid} => #{exc.inspect}"
    false
  end

end # class
end # module


