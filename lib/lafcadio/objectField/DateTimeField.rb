require 'lafcadio/util'
require 'lafcadio/objectField/ObjectField'

module Lafcadio
	# DateTimeField represents a DateTime.
	class DateTimeField < ObjectField
		def valueForSQL(value) # :nodoc:
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

		def valueFromSQL(dbi_value, lookupLink = true) # :nodoc:
			dbi_value ? dbi_value.to_time : nil
		end
	end
end