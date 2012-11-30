require File.expand_path('../spec_helper', __FILE__)

$:.unshift File.expand_path('../../example', __FILE__)

require 'asir/coder/database'
require 'asir/coder/active_record'
require 'asir/transport/database'
require 'asir/coder/yaml'
require 'asir/coder/json'

describe "ASIR::Coder::ActiveRecord" do
  attr_accessor :message, :data, :object, :coder, :transport

  before(:each) do
    self.data = { }
    self.object = ASIR::Test::TestObject.new(nil)
    self.message = ASIR::Message.new(object, nil, nil, nil, nil)
    ActiveRecord::Base.
      establish_connection({
                             :adapter => 'postgresql',
                             :host => '127.0.0.1',
                             :port => 5432,
                             :username => 'test',
                             :password => 'test',
                             :database => 'test',
                           })
    # Probe for tables
    begin
      ASIR::Coder::ActiveRecord::MessageModel.find(:first)
    rescue ActiveRecord::StatementInvalid => exc
      if exc.message =~ /does not exist/
        ASIR::Coder::ActiveRecord::MIGRATIONS.each do | m |
          m.migrate(:up)
        end
      end
    end

    self.coder =
      ASIR::Coder::Database.
      new(
      :message_model => ASIR::Coder::ActiveRecord::MessageModel,
      :result_model  => ASIR::Coder::ActiveRecord::ResultModel,
      :payload_coder => ASIR::Coder::Yaml.new,
      :additional_data_coder => ASIR::Coder::JSON.new,
      )
  end

  it 'should encode Message.' do
    message.selector = :instance_method!
    m = coder.prepare.encode(message)
  end

  it 'should decode Message.' do
  end

  it 'should return result.' do
  end

  it 'should capture exceptions.' do
  end

  it 'should capture Unforwardable exceptions.' do
  end

end

