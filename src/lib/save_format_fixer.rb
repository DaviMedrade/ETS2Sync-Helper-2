require_relative("status_label")

class ETS2SyncHelper::SaveFormatFixer < Qt::GroupBox
	slots("config_dir_changed()", "fix_clicked()", "save_format_changed()")
	signals("changed(bool)")

	def ets2
		@parent.ets2
	end

	def initialize(parent)
		@parent = parent
		super(MSG[:save_format], parent)
		@txt = Qt::LineEdit.new(ets2.config_dir.to_win, self)
		@txt.read_only = true
		@lbl = ETS2SyncHelper::StatusLabel.new(self)
		@btn_fix = Qt::PushButton.new(MSG[:fix_save_format], self)
		connect(@btn_fix, SIGNAL("clicked()"), self, SLOT("fix_clicked()"))
		hbox = Qt::HBoxLayout.new
		hbox.add_widget(@lbl)
		hbox.add_widget(@btn_fix, 1, Qt::AlignRight)
		vbox = Qt::VBoxLayout.new
		vbox.add_widget(@txt)
		vbox.add_layout(hbox)
		set_layout(vbox)
		connect(parent, SIGNAL("config_dir_changed()"), self, SLOT("config_dir_changed()"))
		connect(parent, SIGNAL("save_format_changed()"), self, SLOT("save_format_changed()"))
	end

	def config_dir_changed
		update_status
	end

	def save_format_changed
		update_status
	end

	def fix_clicked
		msgbox = Qt::MessageBox.new
		msgbox.text = MSG[:fix_save_format_prompt]
		msgbox.informative_text = MSG[:are_you_sure]
		msgbox.standard_buttons = Qt::MessageBox::Yes | Qt::MessageBox::No
		msgbox.default_button = Qt::MessageBox::Yes
		msgbox.window_title = APP_NAME
		msgbox.icon = Qt::MessageBox::Question
		if msgbox.exec == Qt::MessageBox::Yes
			ets2.set_save_format(0)
			emit changed(ets2.save_format == 0)
			if ets2.save_format != 0
				msgbox = Qt::MessageBox.new
				msgbox.standard_buttons = Qt::MessageBox::Ok
				msgbox.window_title = APP_NAME
				msgbox.text = MSG[:save_format_change_failed]
				msgbox.informative_text = MSG[:save_format_change_failed_prompt]
				msgbox.icon = Qt::MessageBox::Warning
				msgbox.exec
			end
		end
	end

	def update_status(fix: false)
		if ets2.valid?
			@txt.text = ets2.save_format_line
			case ets2.save_format
			when 0
				@lbl.success(MSG[:status_ok])
				@btn_fix.enabled = false
			when 2, 3
				@lbl.warning(MSG[:save_format_not_recommended])
				@btn_fix.enabled = true
			else
				@lbl.failure(MSG[:save_format_unknown])
				@btn_fix.enabled = true
			end
		else
			@lbl.failure("")
			@txt.text = ""
			@btn_fix.enabled = false
		end
	end
end
