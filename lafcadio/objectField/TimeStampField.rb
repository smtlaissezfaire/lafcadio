require 'lafcadio/objectField/DateTimeField'

class TimeStampField < DateTimeField
	def initialize (objectType)
		super objectType, 'timeStamp'
		@hideDisplay = true
		@notNull = false
	end

	def dbWillAutomaticallyWrite
		true
	end
end

