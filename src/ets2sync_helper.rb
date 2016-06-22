begin
	$LOAD_PATH << __dir__+"/lib"
	if ARGV.first && ARGV.first.match(/^[a-z]{2}(?:-[A-Z]{2})?$/)
		require_relative "lang/#{ARGV.first}"
	else
		require_relative "lang/en.rb"
	end

	APP_NAME = "ETS2Sync Helper"
	Dir.chdir(__dir__)
	require_relative "lib/ets2sync_helper"

	app = Qt::Application.new(ARGV)
	ETS2SyncHelper.new
	app.exec
rescue Exception => e
	puts "/!\\ Exception /!\\"
	puts "#{e.class} - #{e.message}"
	puts "\t#{e.backtrace[0..3].join("\t\n")}"
	puts
	puts "Press any key to close..."
	gets
end
