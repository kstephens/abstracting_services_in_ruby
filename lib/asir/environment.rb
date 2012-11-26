require 'asir'

module ASIR; class Environment
  attr_accessor :phase
  attr_accessor :verb, :adjective, :object, :identifier
  attr_accessor :config_rb, :config
  attr_accessor :log_dir, :log_file, :pid_dir
  attr_accessor :options
  attr_accessor :verbose

  def initialize
    @verbose = 0
    @exit_code = 0
    @options = { }
  end

  def log_dir
    @log_dir ||= find_writable_directory :log_dir,
    ENV['ASIR_LOG_DIR'],
    '/var/log/asir',
    '~/asir/log',
    '/tmp'
  end

  def pid_dir
    @pid_dir ||= find_writable_directory :pid_dir,
      ENV['ASIR_PID_DIR'],
      '/var/run/asir',
      '~/asir/run',
      '/tmp'
  end

  def find_writable_directory kind, *list
    list.
      reject { | p | ! p }.
      map { | p |  File.expand_path(p) }.
      find { | p | File.writable?(p) } or
      raise "Cannot find writable directory for #{kind}"
  end

  def pid_file
    @pid_file ||=
      "#{pid_dir}/#{asir_basename}.pid"
  end

  def log_file
    @log_file ||=
      "#{log_dir}/#{asir_basename}.log"
  end

  def asir_basename
    "asir-#{adjective}-#{object}-#{identifier}"
  end

  def config_rb
    @config_rb ||=
      File.expand_path(ENV['ASIR_CONFIG_RB'] || 'config/asir_config.rb')
  end

  def config! phase, opts = { }
    ((@config ||= { })[phase] ||= [
      begin
        opts[:phase] = phase
        save = { }
        opts.each do | k, v |
          save[k] = send(k)
          send(:"#{k}=", v)
        end
        $stderr.puts "#{self.class} calling #{config_rb} asir.phase=#{phase.inspect} ..." if @verbose >= 1
        value = config_lambda.call(self)
        $stderr.puts "#{self.class} calling #{config_rb} asir.phase=#{phase.inspect} DONE" if @verbose >= 1
        value
      ensure
        save.each do | k , v |
          send(:"#{k}=", v)
        end
      end
      ]).first
  end

  def config_lambda
    @config_lambda ||=
      (
        file = config_rb
        $stderr.puts "#{self.class} loading #{file} ..." if @verbose >= 1
        expr = File.read(file)
        expr = "begin; lambda do | asir |; #{expr}\n end; end"
        cfg = Object.new.send(:eval, expr, binding, file, 1)
        # cfg = load file
        # $stderr.puts "#{self.class} loading #{file} DONE" if @verbose >= 1
        raise "#{file} did not return a Proc, returned a #{cfg.class}" unless Proc === cfg
        cfg
      )
  end

end; end


