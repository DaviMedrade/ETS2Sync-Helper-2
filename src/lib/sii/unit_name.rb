module SII
	module UnitName
		TABLE = [nil]
		TABLE.concat(('0'..'9').to_a.map(&:freeze))
		TABLE.concat(('a'..'z').to_a.map(&:freeze))
		TABLE << "_".freeze

		SEPARATOR = ".".freeze
		NAMELESS_PART_FORMAT = ".%04X".freeze

		@decode_cache = {}
		@nameless_cache = {}

		def self.decode(n)
			n = n.to_i
			return @decode_cache[n] if @decode_cache.has_key?(n)
			code = n
			s = ""
			while n > 0
				n, cn = n.divmod(38)
				raise(UndefinedCharacterError, "undefined character: #{cn}") if cn.zero?
				s << TABLE[cn]
			end
			@decode_cache[code] = s
		end

		def self.nameless(n)
			return @nameless_cache[n] if @nameless_cache.has_key?(n)
			s = sprintf("_nameless.%04X.%04X.%04X.%04X", n >> 48 & 0xffff, n >> 32 & 0xffff, n >> 16 & 0xffff, n & 0xffff)
			@nameless_cache[n] = s
		end

		def self.read(io)
			v = io.read(1).ord
			if v == 0xFF
				nameless(io.read(8).unpack("Q".freeze).first)
			else
				s = io.read(8 * v)
				s.unpack("Q#{v}").collect{|n| decode(n) }.join(SEPARATOR)
			end
		rescue UndefinedCharacterError => e
			raise UndefinedCharacterError, "decoding #{s.inspect}: #{e.message}"
		end

		class UndefinedCharacterError < ArgumentError ; end
	end
end
