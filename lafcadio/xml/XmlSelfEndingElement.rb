require 'lafcadio/xml/XmlElement'

class XmlSelfEndingElement < XmlElement
	def toXml(level = 0)
		spaces(level).to_s + "<#{@name}" + attributeString + "/>\n"
	end
end