require 'lafcadio/html/Element'

class HTML < Array
	class IMG < Element
		def IMG.attributes
			[ 'src' ]
		end

		def IMG.requiredAttributes
			[ 'src' ]
		end
	end
end