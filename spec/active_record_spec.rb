require File.expand_path('../spec_helper', __FILE__)

$:.unshift File.expand_path('../../example', __FILE__)

require 'asir/coder/database'
require 'asir/coder/active_record'
require 'asir/transport/database'
require 'asir/coder/yaml'
require 'asir/coder/json'

describe "ASIR::Coder::ActiveRecord" do
  attr_accessor :message, :result, :data, :object, :coder, :transport

  before :each do
    self.data = { }
    self.object = ASIR::Test::TestObject.new(nil)
    self.message = ASIR::Message.new(object, nil, nil, nil, nil)
    message.create_identifier!

    self.result = ASIR::Result.new(message, nil)

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

  context "with sample Message and Result" do
    attr_accessor :m, :r

    before :each do
      message.selector = :instance_method!
      message.arguments = [ 1, "two", :three, 4.0 ]
      message[:external_id] = 1234
      message[:foo] = "bar"

      result.result = "A String Result"
    end
  context "with saved MessageModel" do
    before :each do
      self.m = coder.prepare.encode(message)
      m.prepare_for_save!
      # $stderr.puts m.inspect
      m.save!
      m.id.should > 0
      message[:database_id].should == m.id
      self.m = m.class.find(m.id)
      # $stderr.puts m.payload
    end

    it 'should encode Message.' do
      m.external_id.should == message[:external_id]
      m.receiver_class.should == message.receiver.class.name
      m.message_type.should == '#'
      m.selector.should == message.selector.to_s
      ad = coder.additional_data_coder.prepare.decode(m.additional_data)
      ad.keys.size.should == 2
      ad['external_id'].should == message[:external_id]
      ad['foo'].should == message[:foo]
      m.description.should == "#{message.receiver.class.name}\##{message.selector}"
      m.delay.should == nil
      m.one_way.should == nil
      m.payload.class.should == String
    end

    it 'should decode Message.' do
      message_ = coder.prepare.decode(m)
      message_.receiver.class.should == message.receiver.class
      message_.selector.should == message.selector
      message_.arguments.should == message.arguments
      message_.description.should == message.description
        ad = message.additional_data.dup
        ad.delete(:database_id).should == m.id
      message_.additional_data.should == ad
    end

      context "with saved ResultModel." do
        before :each do
          result[:external_id] = 3456
          result[:bar] = "A String for Result"
          # result.message = nil # Simulate Transport#...
          self.r = coder.prepare.encode(result)
          r.prepare_for_save!
          # $stderr.puts m.inspect
          r.save!
          r.id.should > 0
          result[:database_id].should == r.id
          self.r = r.class.find(r.id)
          # $stderr.puts r.payload
        end

        it 'should encode Result.' do
          r.message_id.to_i.should == m.id
          r.external_id.should == 3456
          r.result_class.should == "String"
          r.exception_class.should == nil
          r.exception_message.should == nil
          r.exception_backtrace.should == nil
          # Note: JSON does not support Symbols.
          ad = coder.additional_data_coder.prepare.decode(r.additional_data)
          ade = result.additional_data
          ad.keys.size.should == 2
          ad['bar'].should == ade[:bar]
          ad['external_id'].should == ade[:external_id]
          r.payload.class.should == String
        end

        it 'should decode Result.' do
          result_ = coder.prepare.decode(r)
          result_.result.class.should == result.result.class
          # Note: YAML does support Symbols.
          ad = result_.additional_data
          ade = result.additional_data.dup
          ade.delete(:database_id).should == r.id
          ad.should == ade
        end

      it 'should capture Unforwardable exceptions.' do
      end
    end
  end # context
  end # context
end

