require 'lafcadio/util'
require 'lafcadio/objectField/ObjectField'

class DateTimeField < ObjectField
	def valueFromSQL(dbi_value, lookupLink = true)
		dbi_value ? dbi_value.to_time : nil
	end

	def valueForSQL(value)
		if value
			year = value.year
			month = value.mon.to_s.pad( 2, "0" )
			day = value.day.to_s.pad( 2, "0" )
			hour = value.hour.to_s.pad( 2, "0" )
			minute = value.min.to_s.pad( 2, "0" )
			second = value.sec.to_s.pad( 2, "0" )
			"'#{year}-#{month}-#{day} #{hour}:#{minute}:#{second}'"
		else
			"null"
		end
	end
end
