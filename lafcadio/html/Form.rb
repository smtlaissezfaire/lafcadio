require 'lafcadio/html/HTML'
require 'lafcadio/html/ContainerElement'

class HTML
	class Form < ContainerElement
		def Form.attributes
			[ 'name', 'enctype', 'action', 'method' ]
		end

		def Form.requiredAttributes
			[ 'action' ]
		end

		def initialize(attHash = {}, firstElt = nil)
			attHash['method'] = 'post' unless attHash['method']
			super attHash, firstElt
		end

		def multipart=(isMultipart)
			@enctype = 'multipart/form-data' if isMultipart
		end
	end
end