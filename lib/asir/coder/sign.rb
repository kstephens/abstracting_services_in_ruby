require 'digest/sha1'

module ASIR
  class Coder
    # !SLIDE
    # Sign Coder
    #
    # Sign payload during encode, check signature during decode.
    #
    # Signature is the digest of secret + payload.
    #
    # Encode payload as Hash containing the digest function name, signature and payload.
    # Decode and validate Hash containing the digest function name, signature and payload.
    #
    class Sign < self
      attr_accessor :secret, :function

      def _encode obj
        payload = obj.to_s
        { :function  => function,
          :signature => ::Digest.const_get(function).
                          new.hexdigest(secret + payload),
          :payload   => payload }
      end

      def _decode obj
        raise SignatureError, "expected Hash, given #{obj.class}" unless Hash === obj
        payload = obj[:payload]
        raise SignatureError, "signature invalid" unless obj == _encode(payload)
        payload
      end

      # !SLIDE
      # Sign Coder Support

      # Signature Error.
      class SignatureError < Error; end

      def initialize_before_opts
        @function = :SHA1
      end

      # Completely stateless.
      def dup; self; end
      # !SLIDE END
    end 
    # !SLIDE END
  end # class
end # class


