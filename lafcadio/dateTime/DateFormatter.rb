class DateFormatter
	def initialize (f)
		@format = f
		@sprintfFormat = (@format =~ /%/) != nil
	end

	def monthName (month)
		[ 'January', 'February', 'March', 'April', 'May', 'June', 'July',
				'August', 'September', 'October', 'November', 'December' ][month - 1]
	end

	def dayName (date)
		[ 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday',
				'Saturday' ][ date.wday ]
	end
	
	def monthAbbrev (date)
		[ 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct',
				'Nov', 'Dec' ][ date.mon - 1 ]
	end
	
	def getTime (date)
		date.type == Date ? DateTimeUtil.dateToTime (date) : date
	end

	def to_s (date)
		if date
			str = @format.clone
			if @sprintfFormat
				sprintfArgs = []
				str.gsub!(/(yyyy|yy|mm|dd|hh|mn|ss)/) { |match|
					if match == 'yyyy'
						nextArg = date.year
					elsif match == 'yy'
						nextArg = date.year.divmod(100)[1]
					elsif match == 'mm'
						nextArg = date.month
					elsif match == 'dd'
						nextArg = date.day
					elsif match == 'hh'
						nextArg = getTime(date).hour
					elsif match == 'mn'
						nextArg = getTime(date).min
					elsif match == 'ss'
						nextArg = getTime(date).sec
					end
					sprintfArgs << nextArg
					'd'
				}
				str = sprintf str, *sprintfArgs
			else
				str = str.gsub /yyyy/, date.year.to_s
				str = str.gsub /mm/, date.month.to_s
				str = str.gsub /dd/, date.day.to_s
			end
			str = str.gsub /month/, monthName(date.month)
			str = str.gsub /day/, dayName(date)
			str = str.gsub /mon/, monthAbbrev(date)
		else
			str = ''
		end
		str
	end
end
