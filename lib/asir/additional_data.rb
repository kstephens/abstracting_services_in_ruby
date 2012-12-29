module ASIR
  # !SLIDE
  # Addtional Data
  #
  # Support additional data attached to any object.
  module AdditionalData
    def _additional_data; @additional_data; end
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

    def self.included target
      super
      target.extend(ModuleMethods)
    end

    module ModuleMethods
      # Provide a getter method that delegates to addtional_data[...].
      def addit_getter *names
        names.each do | name |
          name = name.to_sym
          define_method(name) { | | self[name] }
        end
      end

      # Provide getter and setter methods that delegate to addtional_data[...].
      def addit_accessor *names
        addr_getter *names
        names.each do | name |
          name = name.to_sym
          define_method(:"#{name}=") { | v | self[name] = v }
        end
      end
    end

  end
  # !SLIDE END
end

