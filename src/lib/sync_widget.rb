require "net/http"
require "json"

class ETS2SyncHelper::SyncWidget < Qt::GroupBox
	signals("syncing(bool)")
	slots("save_changed()", "sync_clicked()", "update_progress()")

	JOBS_URI = URI("http://sync.dsantosdev.com/list.php")
	PROGRESS_MUTEX = Mutex.new

	def save
		@parent.save
	end

	def initialize(parent)
		@jobs_data = nil
		@parent = parent
		super(MSG[:sync], parent)
		@lbl_compatible = ETS2SyncHelper::StatusLabel.new(self)
		@btn = Qt::PushButton.new("   #{MSG[:do_sync]}   ", self)
		@btn.style_sheet = "QPushButton { font-weight: bold; } QPushButton:enabled { color: #080; }"
		@btn.default = true
		connect(@btn, SIGNAL("clicked()"), self, SLOT("sync_clicked()"))
		hbox = Qt::HBoxLayout.new
		hbox.add_widget(@lbl_compatible)
		hbox.add_widget(@btn, 1, Qt::AlignRight)
		@lbl_status = ETS2SyncHelper::StatusLabel.new(self)
		@lbl_status.bold = false
		@pbr = Qt::ProgressBar.new(self)
		@pbr.minimum = 0
		vbox = Qt::VBoxLayout.new
		vbox.add_layout(hbox)
		vbox.add_widget(@lbl_status)
		vbox.add_widget(@pbr)
		set_layout(vbox)
		@tmr = Qt::Timer.new
		connect(@tmr, SIGNAL("timeout()"), self, SLOT("update_progress()"))
		@progress = {status: nil, error: false, finished: false, percent: nil, save: nil, dlcs: nil}
		connect(parent, SIGNAL("save_changed()"), self, SLOT("save_changed()"))
	end

	def save_changed
		update_status
	end

	def progress(changes = {})
		p = nil
		PROGRESS_MUTEX.synchronize do
			@progress.merge!(changes)
			p = @progress
		end
		p
	end

	def sync_clicked
		@tmr.start(50)
		@btn.enabled = false
		emit syncing(true)
		progress(save: parent.save, dlcs: parent.dlcs)
		#(parent.save.dir + "game.sii.0.txt").write(ETS2::SIIFile.read(parent.save.dir + "game.sii.0"))
		Thread.new do |thr|
			begin
				http = nil
				@jobs_data = ""
				progress(status: "#{MSG[:downloading_job_list]} #{MSG[:connecting]}", error: false, finished: false, percent: nil)
				http = Net::HTTP.start(JOBS_URI.host, JOBS_URI.port)
				progress(status: "#{MSG[:downloading_job_list]} #{MSG[:sending_request]}")
				http.request_get(JOBS_URI) do |response|
					response.value
					length = response['Content-Length'].to_f
					progress(status: "#{MSG[:downloading_job_list]} #{MSG[:receiving_list]}")
					response.read_body do |chunk|
						@jobs_data << chunk
						if length.nil?
							length = response['Content-Length'].to_f
						end
						unless length.nil? || length.zero?
							pc = (@jobs_data.length.to_f / length) * 100
							progress(percent: pc)
						end
					end
				end
			rescue => e
				progress(status: "#{MSG[:error_downloading_list]} #{e.class}: #{e.message}", error: true, finished: true)
			ensure
				http.finish rescue nil
			end
			begin
				p = progress(status: MSG[:inserting_jobs], percent: nil)
				data = JSON.parse(@jobs_data)
				jobs = {}
				data.each do |job|
					k = "#{job["company"]}.#{job["city"]}"
					next unless job["dlc_city"] == "none" || p[:dlcs].include?(job["dlc_city"])
					next unless job["dlc_cargo"] == "none" || p[:dlcs].include?(job["dlc_cargo"])
					if job["company"] == "volvo_dlr" || job["company"] == "scania_dlr" || job["target_company"] == "volvo_dlr" || job["target_city"] == "scania_dlr"
						next unless p[:dlcs].include?("north")
					end
					jobs[k] ||= []
					jobs[k] << job
				end
				p[:save].replace_jobs(jobs)
				progress(error: false, finished: true)
			rescue => e
				progress(status: "#{MSG[:error_inserting_jobs]} #{e.class}: #{e.message}", error: true, finished: true)
			end
		end
	end

	def update_progress
		p = self.progress
		if p[:error]
			@lbl_status.failure(p[:status])
		else
			@lbl_status.progress(p[:status] || "")
		end
		if p[:percent]
			@pbr.maximum = 100 if @pbr.maximum != 100
			@pbr.value = p[:percent].to_i
		elsif @pbr.maximum != 0
			@pbr.maximum = 0
		end
		if p[:finished]
			@btn.enabled = true
			@pbr.value = p[:error] ? 0 : 100
			@pbr.maximum = 100
			unless p[:error]
				@lbl_status.success(MSG[:sync_complete])
			end
			@tmr.stop
			emit syncing(false)
		end
		Qt::CoreApplication.instance.process_events
	end

	def update_status
		save = @parent.save
		if save.nil?
			@lbl_compatible.failure("")
			@btn.enabled = false
		elsif !save.zero_file?
			@lbl_compatible.failure(MSG[:sync_incompatible_save])
			@btn.enabled = false
		else
			@lbl_compatible.success(MSG[:sync_compatible_save])
			@btn.enabled = true
		end
	end
end
