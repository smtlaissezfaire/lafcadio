require 'lafcadio/objectField/DateField'
require 'lafcadio/dateTime/Month'

# Accepts a Month as a value. This field automatically saves in MySQL as a date 
# corresponding to the first day of the month.
class MonthField < DateField
	def MonthField.valueType
		Month
	end

	def valueFromCGI(fieldManager)
		month = fieldManager.getInt("#{name}.month")
		year = fieldManager.getInt("#{name}.year")
		if month && year
			Month.new month, year
		else
			nil
		end
	end

	def valueForSQL(value)
		"'#{value.year}-#{value.month}-01'"
	end
end