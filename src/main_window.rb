class MainWindow < Qt::Widget
	WIDTH = 550

	attr_reader :ets2, :profile, :save, :dlcs

	signals("update_ui()", "config_dir_changed()", "save_format_changed()", "profile_changed()", "save_changed()", "dlcs_changed()", "sync_changed()")
	slots("update_ui_timer()", "change_language()", "show_about()", "dir_selected(const QString &)", "s_format_changed(bool)", "profile_path_changed(const QString &)", "save_path_changed(const QString &)", "dlc_selection_changed(const QString &)", "syncing(bool)")

	def initialize
		super
		@ets2 = ETS2.new(ETS2SyncHelper.settings[:ets2_dir])
		@profile = nil
		@save = nil
		@syncing = false
		self.window_title = APP_NAME
		self.fixed_width = WIDTH
		icon = Qt::Icon.new("res/app.ico")
		self.window_icon = icon
		populate_window
		show
		self.fixed_height = self.height
		center
	rescue Exception => e
		if e.is_a?(SystemExit) || STDOUT.tty?
			fail
		else
			msgbox = Qt::MessageBox.new
			msgbox.standard_buttons = Qt::MessageBox::Ok
			msgbox.window_title = MSG[:error]
			msgbox.window_icon = self.window_icon
			msgbox.text = "#{e.class}: #{e.message}"
			msgbox.icon = Qt::MessageBox::Critical
			msgbox.exec
			exit(1)
		end
	end

	def populate_window
		@menu_bar = Qt::MenuBar.new(self)
		mnu_language = @menu_bar.add_menu(MSG[:language_menu])
		current_lang = ETS2SyncHelper.effective_language_for(ETS2SyncHelper.language)
		available_langs = ETS2SyncHelper.available_languages
		agr_langs = Qt::ActionGroup.new(self)
		available_langs.keys.sort.each do |lang|
			lang_name = available_langs[lang]
			action = Qt::Action.new(lang_name, self)
			action.data = Qt::Variant.from_value(lang.to_s)
			action.checkable = true
			action.checked = (lang == current_lang)
			action.action_group = agr_langs
			action.icon = Qt::Icon.new("res/lang/#{lang}.png")
			connect(action, SIGNAL("triggered()"), self, SLOT("change_language()"))
			mnu_language.add_action(action)
		end

		act_about = Qt::Action.new(MSG[:about_button], self)
		@menu_bar.add_action(act_about)
		connect(act_about, SIGNAL("triggered()"), self, SLOT("show_about()"))

		vbox_main = Qt::VBoxLayout.new(self)
		vbox_main.menu_bar = @menu_bar

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
		v = new_version_available?
		if v
			if v == true
				msgbox = Qt::MessageBox.new
				msgbox.standard_buttons = Qt::MessageBox::Yes | Qt::MessageBox::No
				msgbox.window_title = APP_NAME
				msgbox.window_icon = self.window_icon
				msgbox.text = MSG[:new_version_prompt]
				msgbox.icon = Qt::MessageBox::Information
				if msgbox.exec == Qt::MessageBox::Yes
					Qt::DesktopServices.open_url(Qt::Url.new(ETS2SyncHelper.get_uri(:download).to_s))
					exit(0)
				end
			end
			lbl_update = Qt::Label.new("", self)
			s = MSG[:new_version_available].dup
			s << " <a href='#{ETS2SyncHelper.get_uri(:download)}'>#{MSG[:open_website_prompt]}</a>"
			lbl_update.text = s
			lbl_update.text_interaction_flags = Qt::TextBrowserInteraction
			lbl_update.open_external_links = true
			hbox_close.add_widget(lbl_update)
		end
		@btn_close = Qt::PushButton.new(MSG[:close], self)
		connect(@btn_close, SIGNAL("clicked()"), Qt::CoreApplication.instance, SLOT("quit()"))
		hbox_close.add_widget(@btn_close, 1, Qt::AlignRight)
		vbox_main.add_layout(hbox_close)

		# Kickstart the updates
		emit config_dir_changed
		start_monitor

		@tmr_ui = Qt::Timer.new(self)
		connect(@tmr_ui, SIGNAL("timeout()"), self, SLOT("update_ui_timer()"))
		@tmr_ui.start(1000)
	end

	def update_ui_timer
		if @last_monitor_change_time && (Process.clock_gettime(Process::CLOCK_MONOTONIC) - @last_monitor_change_time) > 0.5
			@last_monitor_change_time = nil
			@ets2 = ETS2.new(ETS2SyncHelper.settings[:ets2_dir])
			emit config_dir_changed
		else
			emit update_ui
		end
	end

	def new_version_available?
		dialog = Qt::Label.new
		dialog.window_flags = Qt::CustomizeWindowHint | Qt::WindowTitleHint # & ~Qt::WindowCloseButtonHint
		dialog.text = "<img src='res/app.ico' align='middle'><br><br>#{MSG[:checking]}"
		dialog.alignment = Qt::AlignCenter
		dialog.window_title = APP_NAME
		dialog.window_icon = self.window_icon
		dialog.set_contents_margins(20, 20, 20, 20)
		dialog.show
		dialog.fixed_size = dialog.size
		center(dialog)
		Qt::Application.process_events
		sleep 0.5 # wait for the window to show
		@check_data = nil
		Thread.new do
			@check_data = ETS2SyncHelper.check_version
		end
		while @check_data.nil?
			Qt::Application.process_events
		end
		dialog.dispose
		return false if @check_data == "current"
		return true if @check_data == "outdated"
		return :bugfix if @check_data == "bugfix"
		msgbox = Qt::MessageBox.new
		msgbox.window_icon = self.window_icon
		msgbox.standard_buttons = Qt::MessageBox::Ok
		msgbox.window_title = MSG[:error]
		msgbox.text = "#{MSG[:check_error]}\n\n#{@check_data}"
		msgbox.icon = Qt::MessageBox::Warning
		msgbox.exec
		exit(1)
	end

	def change_language
		lang = sender.data.value.to_sym
		ETS2SyncHelper.settings[:language] = lang
		ETS2SyncHelper.save_settings
		restart!
	end

	def restart!
		msgbox = Qt::MessageBox.new
		msgbox.window_icon = self.window_icon
		msgbox.standard_buttons = Qt::MessageBox::Ok
		msgbox.window_title = APP_NAME
		msgbox.text = MSG[:about_to_restart] % APP_NAME
		msgbox.icon = Qt::MessageBox::Information
		msgbox.exec
		ETS2SyncHelper.restart!
	end

	def show_about
		AboutWindow.new(self)
	end

	def dir_selected(dir)
		dir = dir.force_encoding("UTF-8").encode("filesystem")
		ETS2SyncHelper.settings[:ets2_dir] = Pathname(Pathname(dir).to_win)
		ETS2SyncHelper.save_settings
		@ets2 = ETS2.new(ETS2SyncHelper.settings[:ets2_dir])
		emit config_dir_changed
		start_monitor
	end

	def start_monitor
		stop_monitor
		@monitor = WDM::Monitor.new
		@last_monitor_change_time = nil
		@monitor.watch_recursively(@ets2.config_dir.to_s, :default) do |change|
			@last_monitor_change_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
		end
		unless defined?(@monitor_exit_registered) && @monitor_exit_registered
			Kernel.at_exit { @monitor.stop if @monitor }
			@monitor_exit_registered = true
		end
		Thread.new { @monitor.run! }
	end

	def stop_monitor
		if defined?(@monitor) && !@monitor.nil?
			@monitor.stop
			@monitor = nil
		end
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
		@menu_bar.enabled = !bool
		emit sync_changed
	end

	def syncing?
		@syncing
	end

	def center(widget = self)
		w = Qt::DesktopWidget.new
		ps_geometry = w.available_geometry(w.primary_screen)
		x = [0, (ps_geometry.width - widget.width) / 2 + ps_geometry.x].max
		y = [0, (ps_geometry.height - widget.height) / 2 + ps_geometry.y].max
		widget.move(x, y)
	end
end
