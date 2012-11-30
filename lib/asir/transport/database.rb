require 'asir'

module ASIR
  class Transport
    # Transport that stores to any model class that responds to:
    #
    # obj.save!
    # obj.database_id
    #
    # See Coder::Database
    #
    class Database < self
      attr_accessor :before_message_save, :after_message_save
      attr_accessor :before_result_save, :after_result_save

      def initialize *args
        super
        self.coder_needs_result_message = true
        self.needs_message_identifier = true
      end

      def _send_message message, message_payload
        if @before_message_save
          @before_message_save.call(self, message, message_payload)
        end
        message_payload.save!
        # message[:database_id] ||= message_payload.database_id
        if @after_message_save
          @after_message_save.call(self, message, message_payload)
        end
        nil # message_state
      end

      def _send_result message, result, result_payload, stream, message_state
        return if one_way? or message.one_way?
        if @before_result_save
          @before_result_save.call(self, message, result, result_payload)
        end
        result_payload.save!
        result[:database_id] = result_payload.database_id
        if @after_result_save
          @after_result_save.call(self, message, result, result_payload)
        end
        nil
      end
    end
  end
end
