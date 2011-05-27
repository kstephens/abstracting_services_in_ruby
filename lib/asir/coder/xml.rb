require 'asir'

gem 'libxml-ruby'
require 'xml'

module ASIR
  class Coder
    class XML < self
      def _encode obj
        @stream = ''
        @dom_id_map = { } # not used, yet
        @dom_id = 0 # not used, yet
        _encode_dom obj
        @stream
      end

      def _decode obj
        @stream = obj
        @dom_id_map = { } # not used, yet
        @dom_id = 0 # not used, yet
        @parser = ::XML::Parser.string(@stream)
        @dom = @parser.parse
        _decode_dom @dom.root
      end

      def _encode_dom obj
        case obj
        when NilClass, TrueClass, FalseClass
          tag_obj(obj)
        when Symbol, Numeric
          tag_obj(obj) do
            @stream << obj.to_s
          end
        when String
          tag_obj(obj, :id) do 
            @stream << obj.to_s
          end
        when Array
          tag_obj(obj, :id) do 
            obj.each do | elem |
              _encode_dom elem
            end
          end
        when Hash
          tag_obj(obj, :id) do 
            obj.each do | key, val |
              _encode_dom key
              _encode_dom val
            end
          end
        else
          tag_obj(obj, :id) do 
            obj.instance_variables.each do | attr |
              val = obj.instance_variable_get(attr)
              key = attr.to_s.sub(/^@/, '')
              tag(key) do 
                _encode_dom val
              end
            end
          end
        end
      end

      def tag_obj obj, with_id = false
        tag_name = obj.class.name.gsub('::', '.')
        if block_given?
          tag(tag_name, with_id ? { :id => obj.object_id } : nil) do
            yield
          end
        else
          tag tag_name
        end
      end

      def tag tag, attrs = nil
        tag = tag.to_s
        if block_given?
          @stream << '<' << tag << ' '
          if attrs
            attrs.each do | key, val |
              @stream << key.to_s << '=' << val.to_s.inspect << ' '
            end
          end
          @stream << '>'
          yield
          @stream << '</' << tag << '>'
        else
          @stream << '<' << tag << ' />'
        end
      end

      ################################################################

      def _decode_dom dom
        cls_name = dom.name
        case cls_name
        when "String"
          dom.content
        when "Symbol"
          dom.content.to_sym
        when "Fixnum", "Bignum"
          dom.content.to_i
        when "Float"
          dom.content.to_f
        when "NilClass"
          nil
        when "TrueClass"
          true
        when "FalseClass"
          false
        when "Hash"
          obj = { }
          key = nil
          dom.each_element do | val |
            if key
              obj[_decode_dom(key)] = _decode_dom(val)
              key = nil
            else
              key = val
            end
          end
          obj
        when "Array"
          obj = [ ]
          dom.each_element do | elem |
            obj << _decode_dom(elem)
          end
          obj
        else
          # $stderr.puts "cls_name = #{cls_name.inspect}"
          cls_name = cls_name.gsub('.', '::')
          # $stderr.puts "cls_name = #{cls_name.inspect}"
          cls = eval("::#{cls_name}") # NASTY!
          obj = cls.allocate
          dom.each_element do | child |
            key = child.name
            val = _decode_dom child.first
            obj.instance_variable_set("@#{key}", val)
          end
          obj
        end
      end
    end
  end
end
