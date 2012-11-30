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
    ASIR::Coder::ActiveRecord::MessageModel.delete_all
    ASIR::Coder::ActiveRecord::ResultModel.delete_all

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
    message[:external_id] = 1234

    m = coder.prepare.encode(message)
    m.save!
    m = m.class.find(m.id)

    m.external_id.should == message[:external_id]
    m.receiver_class.should == message.object.class.name
    m.message_type.should == '#'
    m.selector.should == message.selector.to_s
    m.additional_data.should == ''
    m.description.should == "#{message.object.class.name}\#\#{message.selector}"
    m.delay.should == nil
    m.one_way.should == nil
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

