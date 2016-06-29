module ETS2SyncHelper
	def self.settings
		load_settings unless defined?(@settings)
		@settings
	end

	def self.settings_file
		registry_path = "Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Shell Folders"
		registry_key = Win32::Registry::HKEY_CURRENT_USER.open(registry_path)
		dir = registry_key["Local AppData"] rescue registry_key["Personal"]
		Pathname((dir + "\\ETS2SyncHelper\\settings.json").encode("filesystem"))
	end

	def self.load_settings
		file = settings_file
		default = {
			ets2_dir: ETS2.default_config_dir,
			language: :en
		}
		@settings = default
		if file.file?
			data = JSON.parse(file.read(encoding: "UTF-8"))
			if data.has_key?("ets2_dir") && !data["ets2_dir"].nil?
				@settings[:ets2_dir] = Pathname(Pathname(data["ets2_dir"].encode("filesystem")).to_win)
			end
			if data.has_key?("language") && data["language"].is_a?(String) && data["language"].match(/\A[a-z]{2}(?:-[A-Z]{2})?\z/)
				@settings[:language] = data["language"].to_sym
			end
		end
		return @settings
	rescue
		@settings = default
		return @settings
	end

	def self.save_settings
		file = settings_file
		file.dirname.mkpath unless file.dirname.directory?
		data = {
			"ets2_dir" => @settings[:ets2_dir].to_s.encode("UTF-8"),
			"language" => @settings[:language].to_s
		}
		file.write(JSON.dump(data), encoding: "UTF-8")
	rescue
		return false
	end
end
