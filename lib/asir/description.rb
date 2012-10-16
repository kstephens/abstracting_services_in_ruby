module ASIR
  module Description
    def describe obj, indent = "", more = nil
      case obj
      when nil, ASIR::Coder::Identity
        s = ""; more = nil
      when ASIR::Transport
        s = "#{describe(obj.encoder, indent, "->\n")}#{indent}#{obj.class.name}"
        opts = [ :file, :uri ].
          select { | x | obj.respond_to?(x) && obj.send(x) != nil }.
          map { | x | "#{x}: #{obj.send(x).inspect}" } * ","
        s << "(" << opts << ")" unless opts.empty?
        case
        when obj.respond_to?(:transports)
          s << "->[\n"
          s << obj.transports.map { | x | describe(x, indent + "  ") } * ",\n"
          s << "]"
        when obj.respond_to?(:transport)
          s << "->\n" << describe(obj.transport, indent + "  ")
        end
      when ASIR::Coder::Chain
        s = "#{indent}Chain(\n"
        s << obj.encoders.map { | x | describe(x, indent + "  ") } * "->\n"
        s << ")"
      else
        s = "#{indent}#{obj.class.name}"
      end
      s << more if more
      s
    end

    extend self
  end
end
