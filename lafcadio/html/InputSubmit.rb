require 'lafcadio/html/HTML'
require 'lafcadio/html/Input'

class HTML
	class InputSubmit < Input
		def InputSubmit.requiredAttributes
			[]
		end

		def initialize(attHash = {})
			attHash['type'] = 'submit'
			super attHash
		end
	end
end