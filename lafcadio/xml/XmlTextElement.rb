require 'lafcadio/xml/XmlElement'

class XmlTextElement < XmlElement
	def initialize (n, c)
		super n
		@contents = c.to_s
	end

	def toXml (level = 0)
		spaces(level).to_s + "<#{@name}>#{xmlEncode(@contents)}</#{@name}>\n"
	end
end