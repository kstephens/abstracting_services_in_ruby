require 'asir'
require 'asir/object_resolving'
gem 'libxml-ruby'
require 'xml'

module ASIR
  class Coder
    # !SLIDE
    # XML
    #
    # Encode/Decode objects as XML.
    class XML < self
      class Error < ::ASIR::Error
        class BadIdref < self; end
      end
      def _encode obj
        @stream = ''
        @dom_id_map = { }
        @dom_id = 0
        @cls_tag_map = { }
        encode_dom obj
        @stream
      end

      def _decode obj
        @stream = obj
        @decoder ||= DECODER; @decoder_object = nil
        @dom_id_map = { }
        @dom_id = 0
        @cls_tag_map = { }
        @parser = ::XML::Parser.string(@stream)
        @dom = @parser.parse
        decode_dom @dom.root
      end

      def encode_dom obj
        if dom_id = @dom_id_map[obj.object_id]
          tag_obj(obj, nil, :idref => dom_id.first)
        else
          _encode_dom obj
        end
      end

      def _encode_dom obj
        case obj
        when NilClass, TrueClass, FalseClass
          tag_obj(obj)
        when Numeric
          tag_obj(obj, nil, :v => obj.to_s)
        when Symbol
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
              encode_dom elem
            end
          end
        when Hash
          tag_obj(obj, :id) do 
            obj.each do | key, val |
              encode_dom key
              encode_dom val
            end
          end
        else
          tag_obj(obj, :id) do 
            obj.instance_variables.each do | attr |
              val = obj.instance_variable_get(attr)
              key = attr.to_s.sub(/^@/, '')
              tag(key) do 
                encode_dom val
              end
            end
          end
        end
      end

      def tag_obj obj, with_id = false, attrs = nil
        if block_given?
          tag(cls_tag(obj), with_id ? { with_id => map_obj_to_dom_id!(obj) } : nil) do
            yield
          end
        else
          tag(cls_tag(obj), attrs)
        end
      end

      CC = '::'.freeze; D = '.'.freeze
      def cls_tag obj
        obj = obj.class
        @cls_tag_map[obj] ||= obj.name.gsub(CC, D).freeze
      end

      def map_obj_to_dom_id! obj
        if dom_id = @dom_id_map[obj.object_id]
          dom_id.first
        else
          @dom_id_map[obj.object_id] = [ @dom_id += 1, obj ]
          @dom_id
        end
      end

      B  = '<'.freeze;  S = ' '.freeze; E = '>'.freeze; SE = '/>'.freeze
      BS = '</'.freeze; A = '='.freeze
      def tag tag, attrs = nil
        tag = tag.to_s
        @stream << B << tag << S
        if attrs
          attrs.each do | key, val |
            @stream << key.to_s << A << val.to_s.inspect << S
          end
        end
        if block_given?
          @stream << E; yield; @stream << BS << tag << E
        else
          @stream << SE
        end
      end

      ################################################################

      def decode_dom dom
        if dom_id = dom.attributes[:idref]
          unless obj = @dom_id_map[dom_id]
            raise Error::BadIdref, "in element #{dom}"
          end
          obj
        else
          obj = _decode_dom(dom)
          map_dom_id_to_obj! dom, obj if dom.attributes[:id]
          obj
        end
      end

      def _decode_dom dom
        cls_name = dom.name
        decoder = @decoder[cls_name] || 
          (@decoder_object ||= @decoder['Object'])
        raise Error, "BUG: " unless decoder
        decoder.call(self, dom)
      end

      DECODER = {
        'NilClass'   => lambda { | _, dom | nil },
        'TrueClass'  => lambda { | _, dom | true },
        'FalseClass' => lambda { | _, dom | false },
        'String'     => lambda { | _, dom | (dom.attributes[:v] || dom.content) },
        'Symbol'     => lambda { | _, dom | (dom.attributes[:v] || dom.content).to_sym },
        'Integer'    => lambda { | _, dom | (dom.attributes[:v] || dom.content).to_i },
        'Float'      => lambda { | _, dom | (dom.attributes[:v] || dom.content).to_f },
        "Array" => lambda { | _, dom | 
          obj = [ ]
          _.map_dom_id_to_obj! dom, obj
          dom.each_element do | elem |
            obj << _.decode_dom(elem)
          end
          obj
        },
        'Hash' => lambda { | _, dom |
          obj = { }
          _.map_dom_id_to_obj! dom, obj
          key = nil
          dom.each_element do | val |
            if key
              obj[_.decode_dom(key)] = _.decode_dom(val)
              key = nil
            else
              key = val
            end
          end
          obj
        },
        'Object' => lambda { | _, dom |
          cls_name = dom.name
          # $stderr.puts "cls_name = #{cls_name.inspect}"
          cls = _.tag_cls(cls_name)
          obj = cls.allocate
          _.map_dom_id_to_obj! dom, obj
          dom.each_element do | child |
            key = child.name
            val = _.decode_dom child.first
            obj.instance_variable_set("@#{key}", val)
          end
          obj
        },
      }
      DECODER['Fixnum'] = DECODER['Bignum'] = DECODER['Integer']

      def map_dom_id_to_obj! dom, obj
        dom_id = dom.attributes[:id]
        debugger unless dom_id
        raise Error, "no :id attribute in #{dom}" unless dom_id
        if (other_obj = @dom_id_map[dom_id]) and other_obj.object_id != obj.object_id
          raise Error, "BUG: :id #{dom_id} already used for #{other_obj.class.name} #{other_obj.inspect}"
        end
        @dom_id_map[dom_id] = obj
      end

      include ObjectResolving
      def tag_cls cls_name
        @cls_tag_map[cls_name.freeze] ||= resolve_object(cls_name.gsub('.', '::'))
      end

      # This coder is stateful.
      def prepare; dup; end
    end
    # !SLIDE END
  end
end
