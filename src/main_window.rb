class MainWindow < Qt::Widget
	WIDTH = 550

	attr_reader :ets2, :profile, :save, :dlcs

	signals("config_dir_changed()", "save_format_changed()", "profile_changed()", "save_changed()", "dlcs_changed()", "sync_changed()")
	slots("dir_selected(const QString &)", "s_format_changed(bool)", "profile_path_changed(const QString &)", "save_path_changed(const QString &)", "dlc_selection_changed(const QString &)", "syncing(bool)")

	def initialize
		super
		@ets2 = ETS2.new
		@profile = nil
		@save = nil
		@syncing = false
		self.window_title = APP_NAME
		self.fixed_width = WIDTH
		icon = Qt::Icon.new
		icon.add_file("res/icon_32.png", Qt::Size.new(32, 32))
		icon.add_file("res/icon_16.png", Qt::Size.new(16, 16))
		self.window_icon = icon
		populate_window
		show
		self.fixed_height = self.height
		center
	rescue Exception => e
		if STDOUT.tty?
			fail
		else
			msgbox = Qt::MessageBox.new
			msgbox.standard_buttons = Qt::MessageBox::Ok
			msgbox.window_title = MSG[:error]
			msgbox.text = "#{e.class}: #{e.message}"
			msgbox.icon = Qt::MessageBox::Critical
			msgbox.exec
		end
		exit(1)
	end

	def populate_window
		vbox_main = Qt::VBoxLayout.new(self)

		config_dir_selector = ConfigDirSelector.new(self)
		connect(config_dir_selector, SIGNAL("changed(const QString &)"), self, SLOT("dir_selected(const QString &)"))
		vbox_main.add_widget(config_dir_selector, 1, Qt::AlignTop)

		save_format_fixer = SaveFormatFixer.new(self)
		connect(save_format_fixer, SIGNAL("changed(bool)"), self, SLOT("s_format_changed(bool)"))
		vbox_main.add_widget(save_format_fixer, 1, Qt::AlignTop)

		profile_selector = ProfileSelector.new(self)
		connect(profile_selector, SIGNAL("changed(const QString &)"), self, SLOT("profile_path_changed(const QString &)"))
		vbox_main.add_widget(profile_selector, 1, Qt::AlignTop)

		save_selector = SaveSelector.new(self)
		connect(save_selector, SIGNAL("changed(const QString &)"), self, SLOT("save_path_changed(const QString &)"))
		vbox_main.add_widget(save_selector, 1, Qt::AlignTop)

		dlc_selector = DLCSelector.new(self)
		connect(dlc_selector, SIGNAL("changed(const QString &)"), self, SLOT("dlc_selection_changed(const QString &)"))
		vbox_main.add_widget(dlc_selector, 1, Qt::AlignTop)

		sync_widget = SyncWidget.new(self)
		connect(sync_widget, SIGNAL("syncing(bool)"), self, SLOT("syncing(bool)"))
		vbox_main.add_widget(sync_widget, 1, Qt::AlignTop)

		hbox_close = Qt::HBoxLayout.new
		@btn_close = Qt::PushButton.new(MSG[:close], self)
		connect(@btn_close, SIGNAL("clicked()"), Qt::CoreApplication.instance, SLOT("quit()"))
		hbox_close.add_widget(@btn_close, 1, Qt::AlignRight)
		vbox_main.add_layout(hbox_close)

		# Kickstart the updates
		emit config_dir_changed

		self.layout = vbox_main
	end

	def dir_selected(dir)
		@ets2 = ETS2.new(Pathname(dir.force_encoding("UTF-8").encode("filesystem")))
		emit config_dir_changed
	end

	def s_format_changed(success)
		emit save_format_changed
	end

	def profile_path_changed(path)
		@profile = nil
		if path
			path = Pathname(path.force_encoding("UTF-8").encode("filesystem"))
			@ets2.profiles.each do |profile|
				@profile = profile if profile.dir == path
			end
		end
		emit profile_changed
	end

	def save_path_changed(path)
		@save = nil
		if path
			path = Pathname(path.force_encoding("UTF-8").encode("filesystem"))
			@profile.saves.each do |save|
				@save = save if save.dir == path
			end
		end
		emit save_changed
	end

	def dlc_selection_changed(new_dlcs)
		@dlcs = new_dlcs.split(",")
		emit dlcs_changed
	end

	def syncing(bool)
		@syncing = bool
		@btn_close.enabled = !bool
		emit sync_changed
	end

	def syncing?
		@syncing
	end

	def center
		w = Qt::DesktopWidget.new
		ps_geometry = w.available_geometry(w.primary_screen)
		x = [0, (ps_geometry.width - width) / 2 + ps_geometry.x].max
		y = [0, (ps_geometry.height - height) / 2 + ps_geometry.y].max
		move(x, y)
	end
end