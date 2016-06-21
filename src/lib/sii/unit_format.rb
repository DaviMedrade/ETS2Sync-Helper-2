module SII
	class UnitFormat
		attr_reader :name, :flag, :index1, :index2, :offset, :properties

		def self.by_index(idx)
			@by_index[idx]
		end

		def self.all
			@all_unit_formats
		end

		def self.count
			@all_unit_formats.length
		end

		def self.from_io(io)
			first = nil
			magic = io.read(4)
			if magic != "BSII"
				raise "Unknown save format - #{magic.inspect}"
			end
			@by_index = {}
			@all_unit_formats = []
			loop do
				offset = io.pos
				flag, format = io.read(8).unpack("L2".freeze)
				if format > 0
					io.seek(-4, IO::SEEK_CUR)
					break
				end

				struct_unit = "CL2".freeze
				sizeof_unit = 9
				index1, index2, name_len = io.read(sizeof_unit).unpack(struct_unit)
				if name_len > 64
					io.seek(-(sizeof_unit + 8), IO::SEEK_CUR)
					raise "Invalid name length for unit @ offset #{io.pos} (IO: #{io.inspect})"
				end
				name = io.read(name_len)

				properties = PropertyFormat.from_io(io)
				unit = self.new(name: name, flag: flag, index1: index1, index2: index2, offset: offset, properties: properties)
				first = unit unless first
				@by_index[index2] = unit
				@all_unit_formats << unit
				yield io.pos if block_given?
			end
		end

		def initialize(name:, flag:, index1:, index2:, offset: , properties: [])
			@name = name
			@flag = flag
			@index1 = index1
			@index2 = index2
			@offset = offset
			@properties = properties
		end

		def inspect
			"#<#{self.class}: #{self.name.inspect} (flag: #{self.flag.inspect}, index1: #{self.index1.inspect}, index2: #{self.index2.inspect}, offset: #{"0x%X" % self.offset})\n\tProperties:\n\t\t#{self.properties.collect{|p| p.inspect}.join("\n\t\t")}\n>"
		end
	end
end
