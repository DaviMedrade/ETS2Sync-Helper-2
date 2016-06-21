module SII
	class Unit
		attr_reader :format, :tag, :properties

		def self.by_tag(tag)
			@by_tag[tag]
		end

		def self.all
			@all_units
		end

		def self.count
			@all_units.length
		end

		def self.from_io(io)
			first = nil
			@by_tag = {}
			@all_units = []
			loop do
				v = io.read(4).unpack("L".freeze).first
				break if v.zero?
				tag = UnitName.read(io)
				unit = self.new(format: UnitFormat.by_index(v), tag: tag)
				first ||= unit
				@by_tag[tag] = unit
				@all_units << unit
				unit.properties.each do |prop|
					prop.read_value(io)
				end
				yield io.pos if block_given?
			end
			first
		end

		def self.to_io(io)
			io.puts "SiiNunit\n{".freeze
			@all_units.each_with_index do |unit, unit_idx|
				io.puts "#{unit.format.name} : #{unit.tag} {"
				unit.properties.each do |prop|
					prop.to_io(io)
				end
				io.puts "}".freeze
				io.puts
				yield unit_idx if block_given?
			end
			io.puts "}".freeze
		end

		def initialize(format:, tag:)
			@format = format
			@tag = tag
			@properties = []
			@dumped = false
			format.properties.each do |prop_format|
				@properties << Property.new(format: prop_format)
			end
		end

		def dumped? ; @dumped ; end

		def ==(other)
			@tag == other.tag
		end
	end
end
