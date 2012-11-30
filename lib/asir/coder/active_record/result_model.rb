require 'asir'
require 'active_record/migration'
require 'active_record/base'

module ASIR
  class Coder
    class ActiveRecord
      class ResultModel < ::ActiveRecord::Base
        class Migration < ::ActiveRecord::Migration
          def self.table_name
            :asir_result
          end
          def change
            create_table tn = self.class.table_name do | t |
              t.string :message_id
              t.string :class_name
              t.string :exception_class
              t.string :exception_message
              t.string :exception_backtrace
              t.binary :payload
              t.timestamps
            end
            create_index tn, :message_id, :unique => true
            create_index tx, :class_name
            create_index tx, :selector
            create_index tn, :created_at
          end
        end

        set_table_name Migration.table_name

        attr_accessor :object, :message

        belongs_to :message, :class => 'ASIR::Coder::ActiveRecord::MessageModel'

        validate_exists :message_id
        validate_exists :result_class_name
        validate_exists :payload

        before_save :prepare_for_save!
        def prepare_for_save!
          result = self.object
          message = self.message || result.message
          self.message_id = result.message[:database_id] or raise
          self.result_class_name = result.value.class.name.to_s
          if e = result.exception
            self.exception_class = e.class.name.to_s
            self.exception_message = e.message.to_s
            self.exception_backtrace = (e.backtrace * "\n") << "\n";
          end
        end

      end
    end
  end
end
