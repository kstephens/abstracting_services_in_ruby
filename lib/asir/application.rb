require 'asir/system'

module ASIR
  # Ugly workaround JRuby's lack of fork().
  class Application
    attr_accessor :inc, :verbose

    def initialize
      @inc = [ ]
      @name_to_spawn = { }
    end

    def spawn name, &blk
      name = name.to_sym
      spawn = Spawn.new
      @name_to_spawn[spawn.name = name] = spawn
      spawn.app = self
      spawn.blk = blk
      spawn
    end

    class Spawn
      attr_accessor :name, :blk, :app, :pid, :cmd, :tmp, :tmp_out
      def verbose; app.verbose; end

      def to_s
        "#<#{self.class.name} #{name.inspect} #{@pid} >"
      end

      def go!
        case RUBY_PLATFORM
        when /java/i
          @tmp = "/tmp/#{$$}.#{name}"
          @tmp_out = "#{tmp}.out"
          @tmp_run = "#{tmp}.run"
          File.unlink(@tmp_out) rescue nil
          File.unlink(@tmp_run) rescue nil
          begin
            require 'spoon'
            ruby = ASIR.ruby_path
            # ruby = "/usr/bin/ruby"
            inc = app.inc.map{|x| "-I#{x}"}
            @cmd = [ ruby ]
            @cmd.concat(inc)
            @cmd.concat([ $0, "--asir-spawn=#{name}", @tmp ])
            $stderr.puts "#{self} cmd #{cmd * ' '}" if verbose
            @pid = Spoon.spawnp(*cmd)
            # Wait until started.
            until File.exist?(@tmp_run)
              sleep 0.1
            end
          ensure
            File.unlink(@tmp_run) rescue nil
          end
        else
          @pid = Process.fork(&blk)
        end
        @pid
      end

      def kill
        Process.kill 9, pid
        wait
      end

      def wait
        # Wait until finished and collect output.
        begin
          Process.waitpid(pid)
          while true
            Process.kill(0, pid)
            sleep 1
          end
        rescue Errno::ECHILD, Errno::ESRCH
        ensure
          $stderr.puts "Spawn #{self} finished" if verbose
          @pid = nil
          if tmp_out && File.exist?(tmp_out)
            $stdout.write(File.read(tmp_out))
            File.unlink(tmp_out)
          end
          @tmp_out = nil
        end
      end
    end # class

    def in_spawn?
      return @in_spawn unless @in_spawn.nil?
      @in_spawn = false
      $stderr.puts "#{$$} ARGV = #{ARGV.inspect}" if verbose
      if ARGV.size >= 1 and ARGV[0] =~ /^--asir-spawn=(.*)/
        @in_spawn = $1.to_sym
      end
      @in_spawn
    end

    def main
      if in_spawn?
        begin
          name = @in_spawn
          if tmp = ARGV[1]
            out = "#{tmp}.out"
            run = "#{tmp}.run"
            $stdout = $stderr = File.open(out, "w")
            STDOUT.reopen($stdout); STDERR.reopen($stderr)
            File.open(run, "w") { | fh | fh.puts $$ }
          end
          spawn = @name_to_spawn[name]
          raise "#{$$} #{self} Cannot find spawn name #{name.inspect}" unless spawn
          spawn.blk.call
        ensure
          Process.exit!(0)
        end
      end
      yield if block_given?
    end
  end
end
