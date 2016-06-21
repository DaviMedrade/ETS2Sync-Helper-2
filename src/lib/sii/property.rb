module SII
	class Property
		attr_reader :format, :value

		FALLBACK_PROC = lambda do |char|
			"\\x#{"%02x".freeze % (char.ord & 0xFF)}".freeze
		end

		def initialize(format:)
			@format = format
		end

		def read_raw_value(type, io)
			case type
			when :ulong # ulong first because it's used pretty often
				io.read(4).unpack("L".freeze).first
			when :long
				io.read(4).unpack("l".freeze).first
			when :boolean
				!io.readbyte.zero?
			when :ushort
				io.read(2).unpack("S".freeze).first
			when :long_long
				io.read(8).unpack("q".freeze).first
			when :ulong_long
				io.read(8).unpack("Q".freeze).first
			when :float
				io.read(4).unpack("F".freeze).first
			when :string
				length = read_raw_value(:ulong, io)
				io.read(length)
			when :token
				UnitName.decode(read_raw_value(:ulong_long, io))
			when :unit
				UnitName.read(io)
			when :float_triple_quad
				[read_raw_value(:float_triple, io), read_raw_value(:float_quad, io)]
			when /^(.*)_(array|triple|quad)$/
				ary_len = case $2
				when "array".freeze
					read_raw_value(:ulong, io)
				when "triple".freeze
					3
				when "quad".freeze
					4
				end
				v = Array.new(ary_len)
				v.collect! do |n|
					read_raw_value($1.to_sym, io)
				end
				v
			else
				raise ArgumentError, "unknown format type #{type.inspect}"
			end
		end

		def read_value(io)
			@value = read_raw_value(@format.type || @format.type_id, io)
		end

		def dump_value(type, value, wrap: true)
			needs_wrap = false
			r = case type
			when :ulong
				value == 0xFFFFFFFF ? "nil".freeze : value
			when :ushort
				value == 0xFFFF ? "nil".freeze : value
			when :float
				value.to_i == value && value < 9_000_000 ? value.to_i : "&#{[value].pack("F".freeze).bytes.reverse.collect{|b| "%02x".freeze % b}.join}"
			when :float_quad
				needs_wrap = true
				"#{dump_value(:float, value.first)}; #{dump_value(:float_triple, value[1..-1], wrap: false)}"
			when :float_triple_quad
				"#{dump_value(:float_triple, value.first)} #{dump_value(:float_quad, value.last)}"
			when :string, :token
				value =~ /^[A-Za-z0-9_]+$/ ? value : "\"#{value.encode(Encoding::US_ASCII, fallback: FALLBACK_PROC)}\""
			when :unit
				value.empty? ? "null".freeze : value
			when /^(.*)_array$/
				s = [value.length]
				value.each_with_index do |item, item_idx|
					s << " #{format.name}[#{item_idx}]: #{dump_value($1.to_sym, item)}"
				end
				s.join("\n")
			when /^(.*)_triple$/
				needs_wrap = true
				value.collect{|item| dump_value($1.to_sym, item) }.join(", ".freeze)
			else
				value
			end
			needs_wrap && wrap ? "(#{r})" : r
		end

		def to_io(io)
			io.puts " #{@format.name}: #{dump_value(@format.type, @value)}"
		end
	end
end
