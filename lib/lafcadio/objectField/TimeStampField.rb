require 'lafcadio/objectField/DateTimeField'

module Lafcadio
	class TimeStampField < DateTimeField
		def initialize(objectType, name = 'timeStamp', englishName = nil)
			super( objectType, name, englishName )
			@hideDisplay = true
			@notNull = false
		end

		def dbWillAutomaticallyWrite
			true
		end
	end
end