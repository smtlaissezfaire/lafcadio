class DateFormatter
	def initialize (f)
		@format = f
		@sprintfFormat = (@format =~ /%/) != nil
	end

	def monthName (month)
		[ 'January', 'February', 'March', 'April', 'May', 'June', 'July',
				'August', 'September', 'October', 'November', 'December' ][month - 1]
	end

	def to_s (date)
		if date
			str = @format.clone
			if @sprintfFormat
				sprintfArgs = []
				str.gsub!(/(yyyy|mm|dd)/) { |match|
					if match == 'yyyy'
						nextArg = date.year
					elsif match == 'mm'
						nextArg = date.month
					elsif match == 'dd'
						nextArg = date.day
					end
					sprintfArgs << nextArg
					'd'
				}
				str = sprintf str, *sprintfArgs
			else
				str = str.gsub /yyyy/, date.year.to_s
				str = str.gsub /mm/, date.month.to_s
				str = str.gsub /dd/, date.day.to_s
				str = str.gsub /month/, monthName(date.month)
			end
		else
			str = ''
		end
		str
	end
end
