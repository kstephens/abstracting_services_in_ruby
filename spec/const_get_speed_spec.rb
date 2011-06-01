module ASIR
  module Test
    module NamespaceCost
      module Relative
        def self.m
          Exception
        end
      end
      module Absolute
        def self.m
          ::Exception
        end
      end
    end
  end
end

describe 'Namespace Costs' do
  it "uses dynamic namespacing" do
    do_it ::ASIR::Test::NamespaceCost::Relative
  end
  it "uses static namespacing" do
    do_it ::ASIR::Test::NamespaceCost::Absolute
  end
  def do_it obj
    t0 = Time.now
    10_000_000.times do
      obj.m
    end
    t1 = Time.now
    puts "#{obj} #{t1.to_f - t0.to_f}"
  end
end
