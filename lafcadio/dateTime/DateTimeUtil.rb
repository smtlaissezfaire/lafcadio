require 'date'

class DateTimeUtil
	# Converts a Time into a Date.
	def DateTimeUtil.timeToDate(time)
		Date.new(time.year, time.mon, time.day) if time
	end

	# Converts a Date into a Time, with the time of day set to midnight.
	def DateTimeUtil.dateToTime(date)
		Time.local(date.year, date.month, date.day) if date
	end
end
