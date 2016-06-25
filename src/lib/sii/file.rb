require "stringio"
require "openssl"
require "zlib"

module SII
	module File
		AES_KEY = ["2a5fcb1791d22fb60245b3d8369ed0b2c27371563fbf1f3c9edf6b11825a5d0a"].pack("H64")

		def self.read(file)
			get_text(file.read(mode: "rb"))
		end

		def self.get_text(data)
			magic = data[0..3]
			case magic
			when "ScsC"
				unless OpenSSL::Cipher.ciphers.include?("AES-256-CBC")
					raise RuntimeError, "OpenSSL does not have the AES-256-CBC cipher"
				end
				ciphertext = data[0x38..-1]
				init_vector = data[0x24...0x34]
				cipher = OpenSSL::Cipher.new("AES-256-CBC")
				cipher.decrypt
				cipher.padding = 0
				cipher.key = AES_KEY
				cipher.iv = init_vector
				data = cipher.update(ciphertext)
				data << cipher.final
				get_text(Zlib::Inflate.inflate(data))
			when "BSII"
				StringIO.open(data) do |io|
					SII::UnitFormat.from_io(io)
					SII::Unit.from_io(io)
				end
				data = ""
				StringIO.open(data) do |io|
					SII::Unit.to_io(io)
				end
				# For some reason, the game separates lines with "\r\n\n".
				# Doing the same here is not really necessary (according to my tests,
				# it can load a save with regular line endings),
				# but let's do it to be exact.
				data.gsub!("\n", "\n\n")
				get_text(data)
			else
				data
			end
		end

		class UnknownFormat < StandardError ; end
	end
end
