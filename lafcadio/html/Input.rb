require 'lafcadio/html/HTML'
require 'lafcadio/html/Element'

class HTML
	class Input < Element
		def Input.attributes
			[ 'name', 'value', 'size', 'type' ]
		end

		def Input.requiredAttributes
			[ 'name' ]
		end

		def Input.tagName
			'input'
		end
	end
end