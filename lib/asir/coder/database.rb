require 'asir/coder'

module ASIR
  class Coder
    # !SLIDE
    # Database Coder
    #
    # Construct a database object from a Message or Result object.
    #
    # obj = model.new(:object => raw object, :payload => Binary)
    # obj.payload
    #
    # See Transport::Database:
    #
    # obj.save!
    class Database < self
      # The model for Message objects.
      attr_accessor :message_model
      # The model for Result objects.
      attr_accessor :result_model
      # The model for everything else (rare).
      attr_accessor :other_model

      # The coder object => object_payload, must code to some binary String.
      attr_accessor :payload_coder

      # Callback: call(self, obj, attr_Hash)
      attr_accessor :before_model_new
      # Callback: call(self, obj, model_obj)
      attr_accessor :after_model_new

      def _encode obj
        case
        when Message === obj && message_model
          model = self.message_model
        when Result === obj  && result_model
          model = self.result_model
        else other_model
          model = self.other_model
        else
          model = nil
        end
        if model
          payload = payload_coder.prepare.encode(obj)
          if @before_model_new
            @before_model_new.call(self, obj, attrs)
          end
          attrs = { :object => obj, :payload => payload }
          m = model.new(attrs)
          if @after_model_new
            @after_model_new.call(self, obj, m)
          end
          obj = m
        end
        obj
      end

      def _decode obj
        payload_coder.prepare.decode(obj.payload)
      end

      # Completely stateless.
      def dup; self; end
    end
    # !SLIDE END
  end
end

