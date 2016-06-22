begin
	$LOAD_PATH << __dir__+"/lib"
	require "Qt"
	require "ets2"

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
	Dir.chdir(__dir__)

	app = Qt::Application.new(ARGV)
	MainWindow.new
	app.exec
rescue Exception => e
	puts "/!\\ Exception /!\\"
	puts "#{e.class} - #{e.message}"
	puts "\t#{e.backtrace[0..3].join("\t\n")}"
	puts
	puts "Press any key to close..."
	gets
end
