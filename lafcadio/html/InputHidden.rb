require 'lafcadio/html/HTML'
require 'lafcadio/html/Input'

class HTML
	class InputHidden < Input
		def initialize ( attHash = {} )
			attHash['type'] = 'hidden'
			super attHash
		end
	end
end
