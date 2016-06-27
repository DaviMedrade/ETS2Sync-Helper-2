begin
	require "pathname"
	require "net/http"
	APP_NAME = "ETS2Sync Helper"

	Dir.chdir(__dir__)

	trap("INT") do
		exit(1)
	end

	$LOAD_PATH << __dir__+"/lib"
	require "Qt"
	require "ets2"

	MSGS = {}
	Dir.glob("lang/*rb") do |f|
		require_relative f
	end

	require_relative "version"
	module ETS2SyncHelper
		WEBSITE_BASE_URL = "http://sync.dsantosdev.com/"
		WEBSITE_BASE_APP_URL = "#{WEBSITE_BASE_URL}/app#{"-test" unless ENV["OCRA_EXECUTABLE"]}/"

		if ARGV.first && ARGV.first.match(/^[a-z]{2}(?:-[A-Z]{2})?$/) && MSGS.has_key?(ARGV.first.to_sym)
			LANG = ARGV.first.to_sym
		else
			LANG = :en
		end
		::MSG = MSGS[ETS2SyncHelper::LANG]

		def self.get_uri(type, extra_args = {})
			args = extra_args.merge({v: VERSION, hl: LANG})
			query_string = URI.encode_www_form(args)

			url = case type
			when :website
				"#{WEBSITE_BASE_URL}?#{query_string}"
			when :website_show
				WEBSITE_BASE_URL
			when :check_version
				"#{WEBSITE_BASE_APP_URL}check_version?#{query_string}"
			when :download
				"#{WEBSITE_BASE_APP_URL}new_version?#{query_string}"
			when :sync
				"#{WEBSITE_BASE_APP_URL}sync?#{query_string}"
			end

			URI(url)
		end
	end

	if ENV["OCRA_EXECUTABLE"] && ETS2SyncHelper::LANG != :en
		MSG.default_proc = proc do |h, k|
			MSGS[:en][k]
		end
	else
		MSG.default_proc = proc do |h, k|
			"## Missing: #{k}"
		end
	end

	class Pathname
		def to_win
			to_s.gsub("/", "\\")
		end
	end

	require_relative "check_version"
	require_relative "settings_file"
	require_relative "main_window"
	require_relative "config_dir_selector"
	require_relative "save_format_fixer"
	require_relative "profile_selector"
	require_relative "save_selector"
	require_relative "dlc_selector"
	require_relative "sync_widget"
	require_relative "status_label"
	require_relative "about_window"

	app = Qt::Application.new(ARGV)
	plugin_path = (Pathname(Gem::Specification.find_by_name("qtbindings-qt").gem_dir.encode("filesystem")) + "qtbin\\plugins".encode("filesystem")).to_win
	app.add_library_path(plugin_path)
	MainWindow.new
	app.exec
rescue Exception => e
	if e.is_a?(SystemExit)
		raise
	else
		msg = ["ETS2Sync Helper crashed...\n\nError details:"]
		msg << "#{e.class} - #{e.message}"
		msg += e.backtrace
		File.write("error.log", msg.join("\n")+"\n\n")
		system("start", "cmd", "/c", "COLOR 0A & TYPE error.log & PAUSE")
	end
end
