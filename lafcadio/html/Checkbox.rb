require 'lafcadio/html/HTML'
require 'lafcadio/html/Input'

class HTML
	class Checkbox < Input
		def Checkbox.attributes
			super << 'checked'
		end

		def initialize (attHash = {})
			attHash['type'] = 'checkbox'
			super attHash
		end
	end
end