require 'lafcadio/objectField/ObjectField'
require 'lafcadio/util/StrUtil'

class DateTimeField < ObjectField
	def valueFromSQL (valueStr, lookupLink = true)
		value = nil
		if (valueStr =~ /(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/) ||
				(valueStr =~ /(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})/)
			if $1.to_i != 0
				begin
					value = Time.local $1, $2, $3, $4, $5, $6
				rescue ArgumentError
					raise ArgumentError, "argument out of range for #{ name }: #{ valueStr }", caller
				end
			end
		end
		value
	end

	def valueForSQL (value)
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
