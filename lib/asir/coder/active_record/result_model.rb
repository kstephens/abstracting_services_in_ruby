require 'asir'
require 'active_record/migration'
require 'active_record/base'

module ASIR
  class Coder
    module ActiveRecord
      class ResultModel < ::ActiveRecord::Base
        class Migration < ::ActiveRecord::Migration
          def self.table_name
            :asir_results
          end
          def change
            create_table tn = self.class.table_name do | t |
              t.integer :external_id
              t.string  :message_id,      :null => false
              t.string  :result_class,    :null => false  # NORMALIZE?
              t.string  :exception_class                  # NORMALIZE?
              t.text    :exception_message
              t.text    :exception_backtrace
              t.binary  :additional_data
              t.binary  :payload
              t.timestamps
            end
            add_index tn, :external_id
            add_index tn, :message_id, :unique => true
            add_index tn, :result_class
            add_index tn, :exception_class
            add_index tn, :exception_message
            add_index tn, :created_at
          end
        end
        ActiveRecord::MIGRATIONS << Migration

        self.table_name = Migration.table_name.to_s

        attr_accessor :object, :message

        belongs_to :message, :class_name => 'ASIR::Coder::ActiveRecord::MessageModel'

        validates_uniqueness_of :message_id
        validates_presence_of :message_id
        validates_presence_of :result_class
        validates_presence_of :payload

        before_save :prepare_for_save!
        def prepare_for_save!
          if result = self.object
            message = self.message || result.message
            self.external_id ||= message[:external_id]
            self.message_id = message[:database_id] or raise
            self.result_class = result.result.class.name.to_s
            if String === (ad = result._additional_data)
              self.additional_data ||= ad
            end
            if e = result.exception
              e = EncapsulatedException.new(e) unless EncapsulatedException === e
              self.exception_class = e.exception_class
              self.exception_message = e.exception_message
              self.exception_backtrace = (e.exception_backtrace * "\n") << "\n";
            end
          end
        end

      end
    end
  end
end
