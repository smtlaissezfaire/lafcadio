require 'lafcadio/html/ContainerElement'

class HTML
	class Option < ContainerElement
		def Option.attributes
			[ 'value', 'selected' ]
		end

		def Option.requiredAttributes
			[ 'value' ]
		end
	end
end