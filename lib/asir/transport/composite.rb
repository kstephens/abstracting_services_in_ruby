require 'asir/transport/delegation'
module ASIR
  class Transport
    # !SLIDE
    # A Transport composed of other Transports.
    #
    # Classes that mix this in should define #_send_request(request, request_payload).
    module Composite
      include Delegation

      # Enumerable of Transport objects.
      attr_accessor :transports
      # If true, continue with other Transports when Transport#send_request throws an Exception.
      attr_accessor :continue_on_exception
    end
    # !SLIDE END
  end
end

