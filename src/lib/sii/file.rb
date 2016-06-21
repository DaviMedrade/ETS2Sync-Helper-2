require "stringio"
require "openssl"
require "zlib"

module SII
	module File
		AES_KEY = "\x2a\x5f\xcb\x17\x91\xd2\x2f\xb6\x02\x45\xb3\xd8\x36\x9e\xd0\xb2\xc2\x73\x71\x56\x3f\xbf\x1f\x3c\x9e\xdf\x6b\x11\x82\x5a\x5d\x0a".force_encoding('BINARY')

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
