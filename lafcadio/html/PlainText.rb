class PlainText
	def initialize(text)
		@text = text
	end

	def toHtml
		text = @text
		text.gsub!(/>/, "&gt;")
		text.gsub!(/</, "&lt;")
		text.gsub!( /((\n|^)&gt; .*)+/ ) {
			"<span class=\"quoted_text\">#{ $& }</span>"
		}
		text.gsub!( /http:\/\/\S+/ ) {	"<a href=\"#{ $& }\">#{ $& }</a>" }
		text.gsub!(/\n\n/, "<p>")
		text.gsub!(/\n/, "<br>")
		text.gsub!(/(<br>|<p>)/) { "\n" + $& }
		text
	end
end