require 'lafcadio/objectField/DateTimeField'

module Lafcadio
	class TimeStampField < DateTimeField #:nodoc:
		def initialize(objectType, name = 'timeStamp', englishName = nil)
			super( objectType, name, englishName )
			@notNull = false
		end

		def dbWillAutomaticallyWrite
			true
		end
	end
end
