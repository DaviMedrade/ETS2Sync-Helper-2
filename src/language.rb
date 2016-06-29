module ETS2SyncHelper
	def self.language ; @settings[:language] ; end

	def self.available_languages
		langs = {}
		MSGS.each do |lang, msgs|
			langs[lang] = msgs[:this_language]
		end
		langs
	end

	def self.effective_language_for(lang)
		return lang if MSGS.has_key?(lang)
		lang_s = lang.to_s
		if lang_s.include?("-")
			lang = lang_s.partition("-").first.to_sym
			return lang if MSGS.has_key?(lang)
		end
		:en
	end

	MSGS = {}
	MSG = {}
	Dir.glob("lang/*rb") do |f|
		require_relative f
	end

	MSG.default_proc = proc do |h, k|
		lang = effective_language_for(self.language)
		if MSGS.has_key?(lang) && MSGS[lang].has_key?(k)
			MSGS[lang][k]
		else
			if ENV["OCRA_EXECUTABLE"] && lang != :en && MSGS[:en].has_key?(k)
				MSGS[:en][k]
			else
				"## Missing: #{k}"
			end
		end
	end
end
