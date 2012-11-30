require 'asir/coder/active_record'

module ASIR
  class Coder
    module ActiveRecord
      class MessageModel < ::ActiveRecord::Base
        class Migration < ::ActiveRecord::Migration
          def self.table_name
            :asir_messages
          end
          def self.class_table_name
            :asir_classes
          end
          def change
            create_table tn = self.class.class_table_name do | t |
              t.integer :external_id
              t.string  :class_name
            end
            add_index tn, :class_name, :unique => true

            create_table tn = self.class.table_name do | t |
              t.integer :external_id
              t.string  :message_identifier, :null => false
              t.string  :receiver_class,     :null => false # NORMALIZE?
              t.string  :message_type,       :null => false, :size => 1
              t.string  :selector # NORMALIZE?
              t.binary  :additional_data
              t.text    :description # NORMALIZE?
              t.float   :delay
              t.integer :one_way
              t.binary  :payload
              t.timestamps
            end
            add_index tn, :external_id
            add_index tn, :message_identifier, :unique => true
            add_index tn, [ :receiver_class, :message_type ]
            add_index tn, :selector
            add_index tn, :description
            add_index tn, :created_at
          end
        end
        ActiveRecord::MIGRATIONS << Migration

        self.table_name = Migration.table_name.to_s

        attr_accessor :object

        has_one :result, :class_name => 'ASIR::Coder::ActiveRecord::ResultModel'

        validates_uniqueness_of :message_identifier
        validates_presence_of :receiver_class
        validates_presence_of :message_type
        validates_presence_of :selector
        validates_presence_of :payload

        before_save :prepare_for_save!
        def prepare_for_save!
          if message = self.object
            self.external_id ||= message[:external_id]
            self.message_identifier ||= message.message_identifier
            x = message.message_kind
            self.receiver_class = x[0].to_s
            self.message_type   = x[1].to_s
            self.selector ||= message.selector.to_s
            self.description ||= (message[:description] || message.description).to_s
            if String == (ad = message._additional_data)
              self.additional_data ||= ad
            end
            self.payload ||= object_payload
          end
        end

      end
    end
  end
end
