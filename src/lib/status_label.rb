class ETS2SyncHelper::StatusLabel < Qt::Label
	attr_accessor :bold

	def initialize(*args)
		super
		self.bold = true
	end

	def color= color
		set_style_sheet("QLabel { #{"color: #{color};" unless color.nil?} font-weight: #{bold ? :bold : :normal} }")
	end

	def success(str)
		self.text = str
		self.color = "#080"
	end

	def failure(str)
		self.text = str
		self.color = "#f00"
	end

	def warning(str)
		self.text = str
		self.color = "#990"
	end

	def progress(str)
		self.text = str
		self.color = nil
	end
end
