class AboutWindow < Qt::Dialog
	slots("check_new_version()", "update_version_check()")

	CHECK_VERSION_MUTEX = Mutex.new

	def initialize(parent)
		super
		self.window_title = MSG[:about_title] % APP_NAME
		self.modal = true
		self.window_flags = Qt::WindowTitleHint | Qt::WindowSystemMenuHint | Qt::DialogType | Qt::MSWindowsFixedSizeDialogHint

		vbox_main = Qt::VBoxLayout.new(self)

		hbox_main = Qt::HBoxLayout.new

		lbl_logo = Qt::Label.new(self)
		lbl_logo.pixmap = Qt::Pixmap.new("res\\icon_256.png")
		lbl_logo.set_contents_margins(0, 0, 10, 0)
		hbox_main.add_widget(lbl_logo)

		vbox_info = Qt::VBoxLayout.new
		vbox_info.alignment = Qt::AlignTop

		lbl_app_name = Qt::Label.new(APP_NAME, self)
		f = lbl_app_name.font
		f.point_size = 24
		f.bold = true
		lbl_app_name.font = f
		vbox_info.add_widget(lbl_app_name)

		lbl_version = Qt::Label.new(MSG[:version] % ETS2SyncHelper::VERSION)
		f = lbl_version.font
		f.point_size = 16
		f.bold = true
		lbl_version.font = f
		vbox_info.add_widget(lbl_version)

		hbox_check_version = Qt::HBoxLayout.new
		@lbl_check_icon = Qt::Label.new(self)
		mov_loading = Qt::Movie.new("res\\loading.gif")
		@lbl_check_icon.movie = mov_loading
		mov_loading.start
		@lbl_check_icon.visible = false
		hbox_check_version.add_widget(@lbl_check_icon)
		@lbl_check_status = StatusLabel.new(self)
		@lbl_check_status.visible = false
		hbox_check_version.add_widget(@lbl_check_status)
		@btn_check_version = Qt::PushButton.new(MSG[:check_again], self)
		connect(@btn_check_version, SIGNAL("clicked()"), self, SLOT("check_new_version()"))
		hbox_check_version.add_widget(@btn_check_version, 1, Qt::AlignRight)
		vbox_info.add_layout(hbox_check_version)

		lbl_website = Qt::Label.new(MSG[:about_website] % "<a href='#{ETS2SyncHelper.get_uri(:website)}'>#{ETS2SyncHelper.get_uri(:website_show)}</a>", self)
		lbl_website.text_interaction_flags = Qt::TextBrowserInteraction
		lbl_website.open_external_links = true
		vbox_info.add_widget(lbl_website)

		lbl_author = Qt::Label.new(MSG[:about_author], self)
		lbl_author.text_interaction_flags = Qt::TextBrowserInteraction
		lbl_author.open_external_links = true
		lbl_author.set_contents_margins(0, 20, 0, 0)
		vbox_info.add_widget(lbl_author)

		lbl_api = Qt::Label.new(MSG[:about_api], self)
		lbl_api.text_interaction_flags = Qt::TextBrowserInteraction
		lbl_api.open_external_links = true
		vbox_info.add_widget(lbl_api)

		lbl_translator = Qt::Label.new(MSG[:about_translator], self)
		lbl_translator.text_interaction_flags = Qt::TextBrowserInteraction
		lbl_translator.open_external_links = true
		vbox_info.add_widget(lbl_translator)

		lbl_ruby = Qt::Label.new(MSG[:about_ruby], self)
		lbl_ruby.text_interaction_flags = Qt::TextBrowserInteraction
		lbl_ruby.open_external_links = true
		lbl_ruby.set_contents_margins(0, 20, 0, 0)
		vbox_info.add_widget(lbl_ruby)

		lbl_qt = Qt::Label.new(MSG[:about_qt] % Qt.version, self)
		lbl_qt.text_interaction_flags = Qt::TextBrowserInteraction
		lbl_qt.open_external_links = true
		vbox_info.add_widget(lbl_qt)

		lbl_icons = Qt::Label.new(MSG[:about_icons], self)
		lbl_icons.text_interaction_flags = Qt::TextBrowserInteraction
		lbl_icons.open_external_links = true
		vbox_info.add_widget(lbl_icons)

		hbox_main.add_layout(vbox_info)

		vbox_main.add_layout(hbox_main)

		sep = Qt::Frame.new
		sep.frame_shape = Qt::Frame::HLine
		vbox_main.add_widget(sep)

		btnbox = Qt::DialogButtonBox.new(Qt::DialogButtonBox::Close)
		connect(btnbox, SIGNAL("rejected()"), self, SLOT("reject()"))
		vbox_main.add_widget(btnbox)

		self.layout = vbox_main

		@tmr = Qt::Timer.new
		connect(@tmr, SIGNAL("timeout()"), self, SLOT("update_version_check()"))

		check_new_version
		show
	end

	def check_new_version
		CHECK_VERSION_MUTEX.synchronize do
			@has_new_version = nil
			@checking_new_version = true
			@lbl_check_icon.visible = true
			@lbl_check_status.progress MSG[:checking]
			@lbl_check_status.visible = true
			@btn_check_version.disabled = true
		end
		@tmr.start(50)
		Thread.new do
			begin
				data = ETS2SyncHelper.check_version
				CHECK_VERSION_MUTEX.synchronize do
					@has_new_version = case data
					when "current"
						false
					when "outdated"
						true
					when "bugfix"
						:bugfix
					else
						data
					end
					@checking_new_version = false
				end
			rescue Exception => e
				@has_new_version = "#{e.class}: #{e.message}"
			ensure
				CHECK_VERSION_MUTEX.synchronize do
					@checking_new_version = false
				end
			end
		end
	end

	def update_version_check
		CHECK_VERSION_MUTEX.synchronize do
			if !@checking_new_version
				@lbl_check_icon.visible = false
				if @has_new_version == false
					@lbl_check_status.success MSG[:up_to_date]
				elsif @has_new_version == true || @has_new_version == :bugfix
					@lbl_check_status.failure(MSG[:new_version_available])
					msgbox = Qt::MessageBox.new
					msgbox.standard_buttons = Qt::MessageBox::Yes | Qt::MessageBox::No
					msgbox.window_title = MSG[:new_version_available]
					msgbox.text = MSG[:new_version_prompt]
					msgbox.icon = Qt::MessageBox::Information
					if msgbox.exec == Qt::MessageBox::Yes
						Qt::DesktopServices.open_url(Qt::Url.new(ETS2SyncHelper.get_uri(:download).to_s))
						exit(0)
					end
				else
					@lbl_check_status.failure MSG[:check_error]
					msgbox = Qt::MessageBox.new
					msgbox.standard_buttons = Qt::MessageBox::Ok
					msgbox.window_title = MSG[:error]
					msgbox.text = "#{MSG[:check_error]}\n\n#{@has_new_version}"
					msgbox.icon = Qt::MessageBox::Warning
					msgbox.exec
				end
				@lbl_check_status.visible = true
				@btn_check_version.disabled = false
				@tmr.stop
			end
		end
	end
end
