require 'rubygems'
require 'debug_helper'
$:.unshift File.expand_path('../../lib', __FILE__)

require 'asir'

module ASIR
  module Test
    class TestError < ::Exception; end
    class TestObject
      include ASIR::Client
      attr_accessor :spec, :arg, :cls, :msg, :transport, :message
      def initialize spec
        @spec = spec
      end

      def get_data!
        @transport = ASIR::Transport.current
        @message = @transport && @transport.message
      end

      def return_argument arg
        get_data!
        @arg = arg
        arg
      end

      def raise_exception! cls, msg
        get_data!
        @cls = cls
        @msg = msg
        raise cls, msg
      end
    end
  end
end

require 'minitest'
gem 'mocha'
require 'mocha/setup'

RSpec.configure do |config|
  config.mock_with :mocha
  config.order = "random"
end
