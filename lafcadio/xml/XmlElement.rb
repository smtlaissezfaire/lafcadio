class XmlElement < Array
	def initialize (n, attHash = nil)
		@name = n
		@attributes = attHash
	end

	def xmlEncode (contents)
		safeContents = contents.to_s
		if safeContents
			safeContents.gsub! /&/, "&amp;"
			safeContents.gsub! /</, "&lt;"
			safeContents.gsub! />/, "&gt;"
			safeContents.gsub! /'/, "&apos;"
			safeContents.gsub! /"/, "&quot;"
		end
		safeContents
	end

	def spaces (level)
		"  " * level
	end

	def attributeString
		str = ""
		if @attributes
			@attributes.keys.each { |key| str += " #{key}=\"#{xmlEncode(@attributes[key])}\"" }
		end
		str
	end

	def toXml (level = 0)
		str = spaces(level).to_s + "<#{@name}" + attributeString + ">\n"
		self.each { |child| str += child.toXml (level + 1) }
		str += spaces(level).to_s + "</#{@name}>\n"
	end
end