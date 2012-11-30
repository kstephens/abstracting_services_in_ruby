require 'asir'

require 'active_record'
# require 'active_record/base'
# require 'active_record/migration'

module ASIR
  class Coder
    module ActiveRecord
      MIGRATIONS = [ ]
    end
  end
end

require 'asir/coder/active_record/message_model'
require 'asir/coder/active_record/result_model'

