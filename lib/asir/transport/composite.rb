module ASIR
  class Transport
    # !SLIDE
    # A Transport composed of other Transports.
    #
    module Composite
      attr_accessor :transports, :continue_on_exception, :reraise_first_exception

      def needs_request_identifier?
        transports.any? { | t | t.needs_request_identifier? }
      end

      def needs_request_timestamp?
        transports.any? { | t | t.needs_request_timestamp? }
      end
    end
    # !SLIDE END
  end
end

