require 'lafcadio/html/HTML'
require 'lafcadio/html/ContainerElement'

class HTML
	class NoAttributeElement < ContainerElement
		def NoAttributeElement.attributes
			[]
		end

		def initialize(firstElt = nil)
			super({}, firstElt)
		end
	end
end