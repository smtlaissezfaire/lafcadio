require 'lafcadio/html/ContainerElement'

class HTML < Array
	class TD < ContainerElement
		def TD.attributes
			super.concat [ 'colspan', 'align', 'bgcolor', 'rowspan', 'valign' ]
		end
	end
end