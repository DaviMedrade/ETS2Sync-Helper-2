class SaveSelector < Qt::GroupBox
	slots("profile_changed()", "index_changed(int)", "sync_changed()", "update_status()")
	signals("changed(const QString &)")

	def profile
		@parent.profile
	end

	def initialize(parent)
		@parent = parent
		super(MSG[:select_save], parent)
		@lbl = StatusLabel.new(self)
		@cbo = Qt::ComboBox.new(self)
		connect(@cbo, SIGNAL("currentIndexChanged(int)"), self, SLOT("index_changed(int)"))
		vbox = Qt::VBoxLayout.new
		vbox.add_widget(@lbl)
		vbox.add_widget(@cbo)
		set_layout(vbox)
		connect(parent, SIGNAL("profile_changed()"), self, SLOT("profile_changed()"))
		connect(parent, SIGNAL("sync_changed()"), self, SLOT("sync_changed()"))
		connect(parent, SIGNAL("update_ui()"), self, SLOT("update_status()"))
	end

	def profile_changed
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
		if profile
			saves = profile.saves
			saves.reject!(&:autosave?)
		else
			saves = []
		end
		has_new_save = @cbo.count != saves.length
		while @cbo.count > saves.length
			@cbo.removeItem(@cbo.count - 1)
		end
		cbo_count = @cbo.count
		saves.reverse_each.with_index do |save, idx|
			data = save.dir.to_s
			if idx >= cbo_count
				@cbo.add_item(save.display_name, Qt::Variant.new(data))
			elsif @cbo.item_data(idx).value != data
				@cbo.set_item_data(idx, Qt::Variant.new(data))
				@cbo.set_item_text(idx, save.display_name)
			else
				@cbo.set_item_text(idx, save.display_name)
			end
		end
		@cbo.current_index = 0 if has_new_save && saves.length > 0
		if profile.nil?
			@lbl.failure("")
		elsif saves.empty?
			@lbl.failure(MSG[:no_saves])
		else
			@lbl.success(saves.length == 1 ? MSG[:one_save] : MSG[:saves] % saves.length)
		end
	end
end
