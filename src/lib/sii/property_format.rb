module SII
	class PropertyFormat
		module TYPE
			TYPES_HASH = {
				1 => :string,
				2 => :string_array,
				3 => :token,
				4 => :token_array,
				5 => :float,
				6 => :float_array,
				9 => :float_triple,
				17 => :ulong_triple,
				18 => :long_triple_array,
				24 => :float_quad_array,
				25 => :float_triple_quad,
				37 => :ulong,
				38 => :ulong_array,
				39 => :ulong,
				40 => :ulong_array,
				43 => :ushort,
				44 => :ushort_array,
				49 => :long_long,
				51 => :ulong_long,
				52 => :long_long_array,
				53 => :boolean,
				54 => :boolean_array,
				57 => :unit,
				58 => :unit_array,
				59 => :unit,
				60 => :unit_array,
				61 => :unit #:external_unit
			}

			def self.get(type_number)
				TYPES_HASH[type_number]
			end
		end

		attr_reader :name, :type, :type_id, :value
		def self.from_io(io)
			r = []
			loop do
				type = io.read(4).unpack("L".freeze).first
				if type.zero?
					io.seek(-4, IO::SEEK_CUR)
					break
				end
				name_len = io.read(4).unpack("L".freeze).first
				if name_len > 64
					io.seek(-8, IO::SEEK_CUR)
					raise "Invalid name length for property @ offset #{io.pos} (IO: #{io.inspect})"
				end
				name = io.read(name_len)
				r << self.new(name: name, type_id: type)
			end
			r
		end

		def initialize(name:, type_id:)
			@name = name
			@type_id = type_id
			@type = TYPE.get(type_id)
		end

		def inspect
			"#<#{self.class}: #{self.name.inspect} (type: #{self.type.inspect} (#{self.type_id.inspect}))>"
		end
	end
end
