module ASIR
  # !SLIDE
  # Code Block
  #
  # Encode/decode Message#block.
  module CodeBlock
    # Most coders cannot serialize Procs.
    # But we can attempt to serialize a String representing a Proc.
    def encode_block!
      obj = nil
      if @block && ! ::String === @block_code
        obj ||= self.dup
        obj.block_code = CodeBlock.block_to_code(obj.block)
        obj.block = nil 
      end
      obj
    end

    def decode_block!
      if ::String === @block_code
        @block ||= CodeBlock.code_to_block(@block_code)
        @block_code = nil
      end
      self
    end

    # Returns a block_cache Hash.
    # Flushed every 1000 accesses.
    def self.block_cache
      cache = Thread.current[:'ASIR::CodeBlock.block_cache'] ||= { }
      count = Thread.current[:'ASIR::CodeBlock.block_cache_count'] ||= 0
      count += 1
      if count >= 1000
        cache.clear
        count = 0
      end
      Thread.current[:'ASIR::CodeBlock.block_cache_count'] = count
      cache
    end

    # Uses ruby2ruby, if loaded.
    def self.block_to_code block
      (block_cache[block.object_id] ||=
        [ block.respond_to?(:to_ruby) && block.to_ruby, block ]).
        first
    end

    # Calls eval.
    # May be unsafe.
    def self.code_to_block code
      (block_cache[code.dup.freeze] ||=
        [ eval(@block_code), code ]).
        first
    end

  end
end
