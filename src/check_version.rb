require "net/http"

module ETS2SyncHelper
	def self.check_version
		begin
			data = Net::HTTP.get_response(URI("http://sync.dsantosdev.com/app/check_version?v=#{VERSION}&hl=#{LANG}"))
			data.value
			return data.body
		rescue => e
			return "#{e.class}: #{e.message}"
		end
	end

	DOWNLOAD_URL = "http://sync.dsantosdev.com/app/new_version?v=#{ETS2SyncHelper::VERSION}&hl=#{LANG}"
end
