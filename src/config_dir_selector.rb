class ConfigDirSelector < Qt::GroupBox
	slots("select_clicked()", "dir_selected()", "config_dir_changed()", "restore_clicked()", "refresh_clicked()", "sync_changed()")
	signals("changed(const QString &)")

	def ets2
		@parent.ets2
	end

	def initialize(parent)
		@parent = parent
		super(MSG[:config_dir], parent)
		@txt = Qt::LineEdit.new(ets2.config_dir.to_win, self)
		@txt.read_only = true
		@lbl = StatusLabel.new(self)
		@btn_refresh = Qt::PushButton.new(MSG[:reload], self)
		connect(@btn_refresh, SIGNAL("clicked()"), self, SLOT("refresh_clicked()"))
		@btn_restore = Qt::PushButton.new(MSG[:restore], self)
		connect(@btn_restore, SIGNAL("clicked()"), self, SLOT("restore_clicked()"))
		@btn_select = Qt::PushButton.new(MSG[:choose], self)
		connect(@btn_select, SIGNAL("clicked()"), self, SLOT("select_clicked()"))
		hbox = Qt::HBoxLayout.new
		hbox.add_widget(@lbl)
		hbox.add_widget(@btn_refresh, 1, Qt::AlignRight)
		hbox.add_widget(@btn_restore)
		hbox.add_widget(@btn_select)
		vbox = Qt::VBoxLayout.new
		vbox.add_widget(@txt)
		vbox.add_layout(hbox)
		set_layout(vbox)
		connect(parent, SIGNAL("config_dir_changed()"), self, SLOT("config_dir_changed()"))
		connect(parent, SIGNAL("sync_changed()"), self, SLOT("sync_changed()"))
	end

	def config_dir_changed
		update_status
	end

	def sync_changed
		if parent.syncing?
			@btn_refresh.enabled = false
			@btn_restore.enabled = false
			@btn_select.enabled = false
		else
			@btn_refresh.enabled = true
			@btn_restore.enabled = (ets2.config_dir != ETS2.default_config_dir)
			@btn_select.enabled = true
		end
	end

	def update_status
		if ets2.valid?
			@lbl.success(MSG[:status_ok])
		else
			@lbl.failure(MSG[:config_dir_invalid])
		end
		@btn_restore.enabled = (ets2.config_dir != ETS2.default_config_dir)
	end

	def refresh_clicked
		set_selected_dir(ets2.config_dir.to_s)
	end

	def select_clicked
		@dlg_select = Qt::FileDialog.new
		connect(@dlg_select, SIGNAL("accepted()"), self, SLOT("dir_selected()"))
		@dlg_select.file_mode = Qt::FileDialog::Directory
		@dlg_select.option = Qt::FileDialog::ShowDirsOnly
		@dlg_select.modal = true
		@dlg_select.select_file(ets2.config_dir.to_win)
		@dlg_select.show
	end

	def restore_clicked
		msgbox = Qt::MessageBox.new
		msgbox.text = MSG[:restore_prompt]
		msgbox.informative_text = MSG[:are_you_sure]
		msgbox.standard_buttons = Qt::MessageBox::Yes | Qt::MessageBox::No
		msgbox.default_button = Qt::MessageBox::Yes
		msgbox.window_title = APP_NAME
		msgbox.icon = Qt::MessageBox::Question
		if msgbox.exec == Qt::MessageBox::Yes
			set_selected_dir(ETS2.default_config_dir.to_s)
		end
	end

	def dir_selected
		set_selected_dir(@dlg_select.selected_files.first.force_encoding("UTF-8").encode("filesystem"))
	end

	def set_selected_dir(dir)
		@txt.setText(Pathname(dir).to_win)
		emit changed(dir)
	end
end
