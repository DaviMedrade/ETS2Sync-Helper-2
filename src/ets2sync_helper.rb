begin
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
	puts "Pressione qualquer tecla para fechar."
	gets
end
