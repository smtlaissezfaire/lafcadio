require 'lafcadio/html/ContainerElement'
require 'lafcadio/html/HTML'

class HTML
	class A < ContainerElement
		def A.attributes
			[ 'href' ]
		end

		def A.requiredAttributes
			[ 'href' ]
		end

		def A.tagName
			"a"
		end
	end
end
