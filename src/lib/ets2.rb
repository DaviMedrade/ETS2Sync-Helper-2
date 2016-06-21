require 'pathname'
require 'win32/registry'
require 'openssl'
require 'zlib'

class ETS2
	def self.default_config_dir
		registry_path = "Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Shell Folders"
		registry_key = Win32::Registry::HKEY_CURRENT_USER.open(registry_path)
		Pathname((registry_key["Personal"] + "\\Euro Truck Simulator 2").encode("filesystem")).realpath
	end

	def self.display_time(time)
		secs = (Time.now - time).to_i
		if secs < 60
			secs == 1 ? MSG[:one_sec_ago] : MSG[:secs_ago] % secs
		elsif secs < 3600
			mins = secs / 60
			mins == 1 ? MSG[:one_min_ago] : MSG[:mins_ago] % mins
		else
			time.strftime(MSG[:date_time])
		end
	end

	attr_reader :config_dir, :save_format, :save_format_line

	def initialize(config_dir = ETS2.default_config_dir)
		@config_dir = config_dir.realpath
		@config_file = (@config_dir + "config.cfg")
		@valid = @config_file.file? && (@config_dir + "profiles").directory?
		process_save_format if @valid
		@profiles = nil
	end

	def parse_save_format_line(line)
		m = line.match(/^(\s*uset\s+g_save_format\s+)(?:"(\d+)"|(\d+))\s*/)
		return false unless m
		{prefix: m[1], format: (m[2] || m[3]).to_i}
	end

	def set_save_format(n)
		process_save_format(change: true) do |line|
			line[:prefix] + "\"3\""
		end
	end

	def process_save_format(change: false)
		if change
			new_config_file = (@config_dir + "config.cfg.new")
			new_config_f = new_config_file.open("w")
		end
		@save_format = nil
		@save_format_line = nil
		@config_file.each_line do |line|
			line.chomp!
			unless line.match(/^\s*\#/)
				parsed_line = parse_save_format_line(line)
				if parsed_line
					if change
						new_save_line = yield parsed_line
						line = new_save_line
						parsed_line = parse_save_format_line(line)
					end
					@save_format_line = line
					@save_format = parsed_line[:format]
				end
			end
			new_config_f.puts(line) if change
		end
		if change
			if @save_format.nil?
				@save_format_line = yield parse_save_format_line("uset g_save_format \"100\"")
				@save_format = parse_save_format_line(@save_format_line)[:format]
				new_config_f.puts(@save_format_line)
			end
			new_config_f.close
			new_config_f = nil
			new_config_file.rename(@config_file)
			process_save_format(change: false)
		end
	ensure
		new_config_f.close if new_config_f
	end

	def valid?
		@valid
	end

	def profiles
		return @profiles if @profiles
		@profiles = @valid ? Profile.all_from(self) : []
	end

	def inspect
		"#<#{self.class}:#{"0x%x" % self.object_id} #{config_dir.to_s.inspect} (#{"not " unless @valid}valid)}>"
	end

	class Profile
		attr_reader :ets2, :dir, :name, :saved_at
		def self.all_from(ets2)
			profiles = []
			(ets2.config_dir + "profiles").each_child do |profile_dir|
				next unless profile_dir.directory?
				profile = Profile.new(ets2, profile_dir.realpath)
				profiles << profile if profile.valid?
			end
			profiles.sort_by!(&:saved_at)
			profiles
		end

		def initialize(ets2, profile_dir)
			@ets2 = ets2
			@valid = false
			@dir = profile_dir
			@name = nil
			@raw = nil
			@saved_at = nil
			@saves = nil
			file = @dir + "profile.sii"
			if @ets2.valid? && @dir.directory? && file.file?
				@raw = SII::File.read(file)
				m = @raw.match(/^\s*profile_name:\s+(?:\"(.*)\"|(.*))/)
				@name = (m[1] || m[2]).chomp if m
				@name = "[sem nome]" if @name.empty?
				m = @raw.match(/^\s*save_time:\s+(?:\"(.*)\"|(.*))/)
				@saved_at = Time.at((m[1] || m[2]).chomp.to_i) if m
			end
			@valid = !!(@raw && @name && @saved_at)
		rescue SII::File::UnknownFormat
			@valid = false
		end

		def valid?
			@valid
		end

		def ==(other)
			(@name == other.name && @saved_at == other.saved_at && @dir == other.dir)
		rescue
			false
		end

		def display_name
			"#{@name} — #{ETS2.display_time(@saved_at)}"
		end

		def inspect
			"#<#{self.class}:#{"0x%x" % self.object_id} #{@name.inspect} (#{"not " unless @valid}valid) - #{@dir.to_s.inspect}>"
		end

		def saves
			return @saves if @saves
			@saves = @valid ? Save.all_from(self) : []
		end
	end

	class Save
		attr_reader :profile, :dir, :name, :saved_at

		def self.all_from(profile)
			saves = []
			(profile.dir + "save").each_child do |save_dir|
				next unless save_dir.directory?
				save = Save.new(profile, save_dir.realpath)
				saves << save if save.valid?
			end
			saves.sort_by!(&:saved_at)
			saves
		end

		def initialize(profile, save_dir)
			@profile = profile
			@valid = false
			@dir = save_dir
			@name = nil
			@raw = nil
			@saved_at = nil
			@save_file = false
			file = @dir + "info.sii"
			if @profile.valid? && @dir.directory? && file.file?
				@raw = SII::File.read(file)
				m = @raw.match(/^\s*name:\s+(?:\"(.*)\"|(.*))/)
				@name = (m[1] || m[2]).chomp if m
				@name = MSG[:no_name] if @name.empty?
				m = @raw.match(/^\s*file_time:\s+(?:\"(.*)\"|(.*))/)
				@saved_at = Time.at((m[1] || m[2]).chomp.to_i) if m
				@save_file = (@dir + "game.sii").file?
			end
			@valid = !!(@raw && @name && @saved_at)
		rescue SII::File::UnknownFormat
			@valid = false
		end

		def replace_jobs(new_jobs)
			old_file = @dir + "game.sii.0"
			new_file = @dir + "game.sii.new.txt"
			real_new_file = @dir + "game.sii"
			new_file_h = new_file.open("w")
			exp_time = nil
			city_jobs = nil
			current_job = nil
			blank_job = {
				"cargo" => "null",
				"variant" => "nil",
				"target_company" => nil,
				"target_city" => nil,
				"urgency" => "nil",
				"distance" => "0",
				"ferry_time" => "0",
				"ferry_price" => "0"
			}
			first_job = true
			SII::File.read(old_file).each_line do |line|
				line.chomp!
				loop do
					unless line.match(/\s+#/)
						case line
						when /^\s*game_time\s*:\s*(?:"(\d+)"|(\d+))/
							exp_time = (($1 || $2).to_i + 30000).to_s
							break
						when /^\s*company\s*:\s*company\.volatile\.([^\s]+)\s*\{/
							city_jobs = new_jobs.fetch($1, [])
							current_job = nil
							break
						when /^\s*job_offer_data\s*:/
							current_job = city_jobs.shift || blank_job
							break
						when /^\s*}/
							current_job = nil
							break
						end
						if current_job
							if first_job
								first_job = false
								raise(ArgumentError, "game_time not found") unless exp_time
							end
							m = line.match(/^(\s*([a-z_]+)\s*:\s*)(.*)$/)
							if m
								prop_def = m[1]
								prop = m[2]
								val = m[3]
								val = val[1..-2] if val.start_with?("\"") && val.end_with?("\"")
								new_val = case prop
								when "cargo", "variant", "urgency", "ferry_time", "ferry_price"
									current_job[prop]
								when "target"
									current_job["target_company"].nil? ? "\"\"" : "\"#{current_job["target_company"]}.#{current_job["target_city"]}\""
								when "expiration_time"
									exp_time
								when "shortest_distance_km"
									current_job["distance"]
								end
								if new_val
									line = prop_def + new_val
								end
							end
						end
					end
					break
				end
				new_file_h.puts(line)
			end
			new_file_h.close
			new_file_h = nil
			new_file.rename(real_new_file)
		ensure
			new_file_h.close if new_file_h
		end

		def valid?
			@valid
		end

		def autosave?
			@dir.basename.to_s.include?("autosave")
		end

		def save_file?
			@zero_file
		end

		def ==(other)
			(@name == other.name && @saved_at == other.saved_at && @dir == other.dir)
		rescue
			false
		end

		def display_name
			"#{@name} — #{ETS2.display_time(@saved_at)}"
		end

		def inspect
			"#<#{self.class}:#{"0x%x" % self.object_id} #{@name.inspect} (#{"not " unless @valid}valid) - #{@dir.to_s.inspect}>"
		end
	end
end
