class ETS2SyncHelper::DLCSelector < Qt::GroupBox
	slots("selection_changed(int)", "sync_changed()")
	signals("changed(const QString &)")

	def initialize(parent)
		@parent = parent
		super("Selecione suas DLCs", parent)
		@chk_north = Qt::CheckBox.new("Scandinavia", self)
		connect(@chk_north, SIGNAL("stateChanged(int)"), self, SLOT("selection_changed(int)"))
		@chk_east = Qt::CheckBox.new("Going East!", self)
		connect(@chk_east, SIGNAL("stateChanged(int)"), self, SLOT("selection_changed(int)"))
		@chk_hpower = Qt::CheckBox.new("High Power Cargo Pack", self)
		connect(@chk_hpower, SIGNAL("stateChanged(int)"), self, SLOT("selection_changed(int)"))
		hbox = Qt::HBoxLayout.new
		hbox.add_widget(@chk_north)
		hbox.add_widget(@chk_east)
		hbox.add_widget(@chk_hpower)
		set_layout(hbox)
		connect(parent, SIGNAL("sync_changed()"), self, SLOT("sync_changed()"))
	end

	def showEvent(e)
		selection_changed(0) unless e.spontaneous
	end

	def sync_changed
		if parent.syncing?
			@chk_north.enabled = false
			@chk_east.enabled = false
			@chk_hpower.enabled = false
		else
			@chk_north.enabled = true
			@chk_east.enabled = true
			@chk_hpower.enabled = true
		end
	end

	def selection_changed(int)
		dlcs = []
		dlcs << "north" if @chk_north.is_checked
		dlcs << "east" if @chk_east.is_checked
		dlcs << "hpower" if @chk_hpower.is_checked
		emit changed(dlcs.join(","))
	end
end
