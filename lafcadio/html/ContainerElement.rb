require 'lafcadio/html/Element'

class HTML
	class ContainerElement < Element
		def ContainerElement.endTag
			"</#{tagName}>"
		end

		def initialize (attHash = {}, firstElt = nil)
			super attHash
			self << firstElt if firstElt
		end

		def toHTML
			super + contents + self.type.endTag
		end

		def contents
			html = ""
			eltToHTML = []
			each { |elt| eltToHTML << eltHTML(elt) }
			eltToHTML.join "\n"
		end

		def eltHTML (elt)
			( elt.respond_to? "toHTML" ) ? elt.toHTML : elt.to_s
		end
	end
end