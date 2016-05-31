begin
	#puts "PATH: #{ENV['PATH'].inspect}\n\n"
	#puts "PATH encoding: #{ENV['PATH'].encoding.inspect}\n\n"
	#puts "dirname: #{File.dirname(__FILE__).inspect}\n\n"
	#puts "dirname encoding: #{File.dirname(__FILE__).encoding.inspect}\n\n"
	#puts "Loading..."
	APP_NAME = "ETS2Sync Helper"
	Dir.chdir(__dir__)
	require_relative "lib/ets2sync_helper"

	#puts "Starting app..."
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
