require 'lafcadio/objectField/DateField'
require 'lafcadio/dateTime'

module Lafcadio
	# Accepts a Month as a value. This field automatically saves in MySQL as a 
	# date corresponding to the first day of the month.
	class MonthField < DateField
		def self.valueType #:nodoc:
			Month
		end

		def valueForSQL(value) #:nodoc:
			"'#{value.year}-#{value.month}-01'"
		end
	end
end