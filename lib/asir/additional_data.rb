module ASIR
  # !SLIDE
  # Addtional Data
  #
  # Support additional data attached to any object.
  module AdditionalData
    def additional_data
      @additional_data || EMPTY_HASH
    end
    def additional_data!
      @additional_data ||= { }
    end
    def additional_data= x
      @additional_data = x
    end
    def [] key
      @additional_data && @additional_data[key]
    end
    def []= key, value
      (@additional_data ||= { })[key] = value
    end
  end
  # !SLIDE END
end

