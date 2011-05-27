module ASIR
    # Generic API error.
  class Error < ::Exception
    # Unsupported Feature.
    class Unsupported < self; end
    # Requested Stop.
    class Terminate < self; end
  end
end
