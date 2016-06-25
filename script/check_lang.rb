require "rubygems"
require "pathname"
require "parser/current"
Parser::Builders::Default.emit_lambda = true # opt-in to most recent AST format

def relative_path(f)
	Pathname(f).relative_path_from(Pathname(".."))
end

def traverse_msg_node(node, lvl = 0)
	r = []
	if node.type == :send
		#puts "send node"
		children = node.children
		if children[0] == AST::Node.new(:const, [nil, :MSG]) && children[1] == :[]
			if children[2].is_a?(AST::Node) && children[2].type == :sym
				return [children[2].children.first]
			else
				puts "WARNING: Called MSG[<not symbol>] (line #{node.loc.line}: #{node.loc.expression.source})"
			end
		else
			#puts "Not getting MSG: #{children.inspect}"
		end
	end
	node.children.each do |child|
		if child.is_a?(AST::Node)
			r += traverse_msg_node(child)
		end
	end
	return r
end

Dir.chdir("script")

langs_to_check = ARGV.dup
if langs_to_check.empty?
	langs_to_check = []
	Dir.glob("../src/lang/*rb").each do |f|
		m = f.match(/lang\/([a-z]{2}(?:-[A-Z]{2})?)\.rb/)
		langs_to_check << m[1]
	end
end
langs_to_check.collect!{|lang| lang.to_sym }
MSGS = {}
Dir.glob("../src/lang/{#{langs_to_check.join(",")}}.rb").each do |f|
	puts "Requiring #{relative_path(f)}"
	require_relative f
end

sources = Dir.glob("../src/**/*rb")
sources.reject!{|f| f.include?("lang/")}

referenced_keys = []
sources.each do |source|
	puts "Parsing #{relative_path(source)}"
	referenced_keys += traverse_msg_node(Parser::CurrentRuby.parse(File.read(source)))
end

puts
has_problems = false
langs_to_check.each do |lang|
	unref = MSGS[lang].keys - referenced_keys
	if unref.any?
		has_problems = true
		puts "#{lang} has extra keys: #{unref.map(&:inspect).join(", ")}"
	end
	not_found = referenced_keys - MSGS[lang].keys
	if not_found.any?
		has_problems = true
		puts "#{lang} doesn't have keys: #{not_found.map(&:inspect).join(", ")}"
	end
end
unless has_problems
	puts "Language definitions OK"
end
