require 'lafcadio/objectField/DateField'
require 'lafcadio/dateTime/Month'

module Lafcadio
	# Accepts a Month as a value. This field automatically saves in MySQL as a 
	# date corresponding to the first day of the month.
	class MonthField < DateField
		def MonthField.valueType #:nodoc:
			Month
		end

		def valueForSQL(value) #:nodoc:
			"'#{value.year}-#{value.month}-01'"
		end
	end
end