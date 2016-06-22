begin
	Dir.chdir(__dir__)

	trap("INT") do
		exit(1)
	end

	$LOAD_PATH << __dir__+"/lib"
	require "Qt"
	require "ets2"

	require_relative "version"
	require_relative "main_window"
	require_relative "config_dir_selector"
	require_relative "save_format_fixer"
	require_relative "profile_selector"
	require_relative "save_selector"
	require_relative "dlc_selector"
	require_relative "sync_widget"
	require_relative "status_label"

	class Pathname
		def to_win
			to_s.gsub("/", "\\")
		end
	end

	if ARGV.first && ARGV.first.match(/^[a-z]{2}(?:-[A-Z]{2})?$/)
		require_relative "lang/#{ARGV.first}"
	else
		require_relative "lang/en.rb"
	end
	MSG.default_proc = proc do |h, k|
		"## Missing: #{k}"
	end

	APP_NAME = "ETS2Sync Helper"

	app = Qt::Application.new(ARGV)
	plugin_path = (Pathname(Gem::Specification.find_by_name("qtbindings-qt").gem_dir.encode("filesystem")) + "qtbin\\plugins".encode("filesystem")).to_win
	app.add_library_path(plugin_path)
	MainWindow.new
	app.exec
rescue Exception => e
	unless e.is_a?(SystemExit)
		msg = ["ETS2Sync Helper crashed...\n\nError details:"]
		msg << "#{e.class} - #{e.message}"
		msg += e.backtrace
		File.write("error.log", msg.join("\n")+"\n\n")
		system("start", "cmd", "/c", "COLOR 0A & TYPE error.log & PAUSE")
	end
end
