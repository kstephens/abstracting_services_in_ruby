module ASIR
  # !SLIDE
  # Object Resolving
  #
  module ObjectResolving
    class ResolveError < Error; end
    def resolve_object name
      name.to_s.split(MODULE_SEP).inject(Object){|m, n| m.const_get(n)}
    rescue Exception => err
      raise ResolveError, "cannot resolve #{name.inspect}: #{err.inspect}", err.backtrace
    end
  end
  # !SLIDE END
end

