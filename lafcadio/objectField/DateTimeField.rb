require 'lafcadio/objectField/ObjectField'
require 'lafcadio/util/StrUtil'

class DateTimeField < ObjectField
	def valueFromSQL(dbi_value, lookupLink = true) 
		dbi_value ? dbi_value.to_time : nil
	end

	def valueForSQL(value)
		if value
			year = value.year
			month = StrUtil.pad value.mon.to_s, 2, "0"
			day = StrUtil.pad value.day.to_s, 2, "0"
			hour = StrUtil.pad value.hour.to_s, 2, "0"
			minute = StrUtil.pad value.min.to_s, 2, "0"
			second = StrUtil.pad value.sec.to_s, 2, "0"
			"'#{year}-#{month}-#{day} #{hour}:#{minute}:#{second}'"
		else
			"null"
		end
	end
end
