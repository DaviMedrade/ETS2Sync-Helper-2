class ETS2SyncHelper::ProfileSelector < Qt::GroupBox
	slots("config_dir_changed()", "index_changed(int)", "sync_changed()")
	signals("changed(const QString &)")

	def ets2
		@parent.ets2
	end

	def initialize(parent)
		@parent = parent
		super("Selecione o Perfil", parent)
		@lbl = ETS2SyncHelper::StatusLabel.new(self)
		@cbo = Qt::ComboBox.new(self)
		connect(@cbo, SIGNAL("currentIndexChanged(int)"), self, SLOT("index_changed(int)"))
		vbox = Qt::VBoxLayout.new
		vbox.add_widget(@lbl)
		vbox.add_widget(@cbo)
		set_layout(vbox)
		connect(parent, SIGNAL("config_dir_changed()"), self, SLOT("config_dir_changed()"))
		connect(parent, SIGNAL("sync_changed()"), self, SLOT("sync_changed()"))
	end

	def config_dir_changed
		update_status
	end

	def sync_changed
		if parent.syncing?
			@cbo.enabled = false
		else
			@cbo.enabled = true
		end
	end

	def index_changed(new_index)
		val = @cbo.item_data(@cbo.current_index).value
		val = val.force_encoding("UTF-8").encode("filesystem") if val
		emit changed(val)
	end

	def update_status
		item_data = @cbo.item_data(@cbo.current_index).value
		if item_data
			prev = Pathname(item_data.force_encoding("UTF-8").encode("filesystem"))
		end
		profiles = ets2.profiles
		emit @cbo.clear
		prev_new_idx = 0
		profiles.reverse_each.with_index do |profile, idx|
			@cbo.add_item(profile.display_name, Qt::Variant.new(profile.dir.to_s))
			if profile.dir == prev
				prev_new_idx = idx
			end
		end
		@cbo.current_index = prev_new_idx
		if !ets2.valid?
			@lbl.failure("")
		elsif profiles.empty?
			@lbl.failure("Nenhum perfil encontrado.")
		else
			@lbl.success("#{profiles.length} #{profiles.length == 1 ? "perfil" : "perfis"}.")
		end
	end
end
