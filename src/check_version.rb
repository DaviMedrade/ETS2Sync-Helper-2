require "net/http"

module ETS2SyncHelper
	def self.check_version
		begin
			data = Net::HTTP.get_response(get_uri(:check_version))
			data.value
			return data.body
		rescue => e
			return "#{e.class}: #{e.message}"
		end
	end
end
