require_relative("status_label")

class ETS2SyncHelper::SaveFormatFixer < Qt::GroupBox
	slots("config_dir_changed()", "fix_clicked()", "save_format_changed()")
	signals("changed(bool)")

	def ets2
		@parent.ets2
	end

	def initialize(parent)
		@parent = parent
		super("Formato do Save", parent)
		@txt = Qt::LineEdit.new(ets2.config_dir.to_win, self)
		@txt.read_only = true
		@lbl = ETS2SyncHelper::StatusLabel.new(self)
		@btn_fix = Qt::PushButton.new("Corrigir…", self)
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
		msgbox.text = "O Formato do Save no seu arquivo de configuração será alterado.\nVocê não pode estar com o jogo aberto."
		msgbox.informative_text = "Tem certeza?"
		msgbox.standard_buttons = Qt::MessageBox::Yes | Qt::MessageBox::No
		msgbox.default_button = Qt::MessageBox::Yes
		msgbox.window_title = APP_NAME
		msgbox.icon = Qt::MessageBox::Question
		if msgbox.exec == Qt::MessageBox::Yes
			ets2.set_save_format(3)
			emit changed(ets2.save_format == 3)
			msgbox = Qt::MessageBox.new
			msgbox.standard_buttons = Qt::MessageBox::Ok
			msgbox.window_title = APP_NAME
			if ets2.save_format == 3
				msgbox.text = "O Formato do Save foi alterado com sucesso."
				msgbox.informative_text = "Entre no jogo, crie um novo save, e clique no botão “Atualizar”."
				msgbox.icon = Qt::MessageBox::Information
			else
				msgbox.text = "A alteração do Formato do Save não funcionou."
				msgbox.informative_text = "Altere manualmente o “g_save_format” do arquivo “config.cfg” na Pasta de Configuração do ETS para “3” e clique no botão “Atualizar”."
				msgbox.icon = Qt::MessageBox::Warning
			end
			msgbox.exec
		end
	end

	def update_status(fix: false)
		if ets2.valid?
			@txt.text = ets2.save_format_line
			if ets2.save_format == 3
				@lbl.success("OK")
				@btn_fix.enabled = false
			else
				@lbl.failure("Formato do Save incorreto (no arquivo: #{ets2.save_format.nil? ? "não encontrado" : ets2.save_format}, correto: 3).")
				@btn_fix.enabled = true
			end
		else
			@lbl.failure("")
			@txt.text = ""
			@btn_fix.enabled = false
		end
	end
end
