require 'date'

class DateTimeUtil
	def DateTimeUtil.timeToDate (time)
		Date.new (time.year, time.mon, time.day) if time
	end

	def DateTimeUtil.dateToTime (date)
		Time.local (date.year, date.month, date.day) if date
	end
end
