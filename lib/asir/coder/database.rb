require 'asir/coder'

module ASIR
  class Coder
    # !SLIDE
    # Database Coder
    #
    # Construct a database object from a Message or Result object.
    #
    # obj = model.new(:object => partially encoded object, :original_object => original object, :payload => Binary)
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
      # The model for everything else.
      attr_accessor :other_model

      # The coder object => object_payload, must code to some binary String.
      attr_accessor :payload_coder, :additional_data_coder

      # Callback: attrs = call(self, obj, attrs : Hash)
      attr_accessor :before_model_new
      # Callback: model_obj = call(self, obj, model_obj)
      attr_accessor :after_model_new

      def _encode in_obj
        obj = in_obj
        case
        when Message === in_obj && message_model
          model = message_model
        when Result === in_obj  && result_model
          model = result_model
        else
          model = other_model
        end
        if model
          obj = in_obj.encode_more!
          # Prepare attributes for Model.
          attrs = { :original_object => in_obj }

          # Encode AdditionalData.
          if AdditionalData === obj and ad = obj._additional_data
            c = additional_data_coder || payload_coder
            attrs[:additional_data] = c.prepare.encode(ad)
          end

          # Results need links back to its Message.
          if Result === obj and message = in_obj.message
            attrs[:message_object] = message
            # Do not encode entire Message in ResultModel#payload.
            obj.message = nil
            if message_id = message[:database_id]
              attrs[:message_id] = message_id
            end
            obj[:external_id] ||= message[:external_id]
            # pp [ :Result_attrs, attrs ]
          end

          # Encode Object payload
          payload = payload_coder.prepare.encode(obj)
          attrs[:object] = obj
          attrs[:payload] = payload

          if @before_model_new
            attr = @before_model_new.call(self, in_obj, attrs)
          end
          m = model.new(attrs)
          if @after_model_new
            m = @after_model_new.call(self, in_obj, m)
          end
          obj = m
        end
        obj
      end

      def _decode obj
        payload_coder.prepare.decode(obj.payload)
      end
    end
    # !SLIDE END
  end
end

