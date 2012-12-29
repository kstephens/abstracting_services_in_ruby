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

      def _send_message message_result
        if @before_message_save
          @before_message_save.call(self, message_result)
        end
        message_result.message_payload.save!
        # message[:database_id] ||= message_payload.database_id
        if @after_message_save
          @after_message_save.call(self, message_result)
        end
      end

      def _send_result message_result
        return if one_way? or message_result.message.one_way?
        if @before_result_save
          @before_result_save.call(self, message_result)
        end
        message_result.result_payload.save!
        result[:database_id] = result_payload.database_id
        if @after_result_save
          @after_result_save.call(self, message_result)
        end
      end
    end
  end
end
