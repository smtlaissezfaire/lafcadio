class HTML < Array
	def initialize(firstEl = nil)
		self[0] = firstEl if firstEl
	end

	def toHTML
		text = ""
		each { |element|
			if element != nil
				text +=(element.respond_to? "toHTML") ? element.toHTML : element
				text += "\n"
			end
		}
		text
	end

	def addHR
		self << "<hr>"
	end

	def addBR
		self << "<br>"
	end

	def addP
		self << "<p>"
	end
end
