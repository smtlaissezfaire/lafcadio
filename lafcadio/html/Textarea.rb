require 'lafcadio/html/ContainerElement'
require 'lafcadio/html/HTML'

class HTML
	class Textarea < ContainerElement
		def Textarea.attributes
			[ 'cols', 'name', 'rows' ]
		end

		def Textarea.requiredAttributes
			[ 'name' ]
		end
	end
end
