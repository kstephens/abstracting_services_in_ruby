require File.expand_path('../spec_helper', __FILE__)

require 'asir'

describe "ASIR Performance" do
  attr_accessor :transport, :data, :object
  attr_accessor :n

  before(:each) do
    self.n = 1_000_000
    self.data = { }
    self.transport = ASIR::Transport::Local.new
    self.object = ASIR::Test::TestObject.new(self)
    object.class.client.transport = transport
  end

  it 'Raw message time' do
    run! do
      object.return_argument :this_value
    end
    $raw_t = @t # FIXME!
  end

  it 'Message time using Transport::Local, Coder::Identity' do
    run! do
      object.client.return_argument :this_value
    end
    that_t = $raw_t # FIXME!
    this_t = @t
    $stderr.puts "\nThis .vs. Raw: #{this_t[:ms_per_n] / that_t[:ms_per_n]} ms/msg / ms/msg"
  end

  def run! &blk
    $stderr.puts "Warmup: #{desc} ..." if @verbose
    (n / 100 + 100).times &blk
    $stderr.puts "Warmup: DONE." if @verbose
    elapsed do
      n.times &blk
    end
  end

  def elapsed
    result = nil
    @t = { }
    $stderr.puts "Measuring: #{desc} ..." if @verbose
    @t[:n] = n
    @t[:t0] = Time.now
    result = yield
    @t[:t1] = Time.now
    @t[:dt] = @t[:t1] - @t[:t0]
    $stderr.puts "Measuring: DONE." if @verbose
    $stderr.puts "\n#{desc}:"
    $stderr.puts "  n       = #{@t[:n]}"
    $stderr.puts "  elapsed = #{@t[:dt]} s"
    $stderr.puts "  rate    = #{@t[:n_per_s] = @t[:n] / @t[:dt]} n/s"
    $stderr.puts "  time    = #{@t[:ms_per_n] = @t[:dt] / @t[:n] * 1000} ms/n"
    result
  end

  def desc
    @desc ||=
      @example.metadata[:description_args] * " "
  end

end

