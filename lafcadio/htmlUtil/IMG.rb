require 'lafcadio/html/IMG'

module HTMLUtil
	class IMG
		def initialize(fileName)
			@fileName = fileName
		end

		def toHTML
			HTML::IMG.new({ 'src' => "/img/#{@fileName}" }).toHTML
		end
	end
end