require 'asir'
require 'active_record/migration'
require 'active_record/base'

module ASIR
  class Coder
    class ActiveRecord
      class MessageModel < ::ActiveRecord::Base
        class Migration < ::ActiveRecord::Migration
          def self.table_name
            :asir_message
          end
          def change
            create_table tn = self.class.table_name do | t |
              t.string :uuid
              t.string :class_name
              t.string :selector
              t.binary :additional_data
              t.string :description
              t.binary :payload
              t.timestamps
            end
            create_index tn, :message_id, :unique => true
            create_index tn, :created_at
          end
        end
        set_table_name Migration.table_name

        attr_accessor :object

        has_one :result, :class => 'ASIR::Coder::ActiveRecord::ResultModel'

        validate_exists :uuid
        validate_exists :class_name
        validate_exists :selector
        validate_exists :payload

        before_save :prepare_for_save!
        def prepare_for_save!
          message = self.object
          self.uuid ||= message[:uuid] || message.uuid # ??
          self.class_name ||= message.class_name.to_s
          self.selector ||= (message[:selector] || message.selector).to_s
          self.description ||= message[:description] || message.description
          self.payload ||= object_payload
        end

      end
    end
  end
end
