# Represents a specific month in time. With the exception of Month.monthNames
# (which returns an array), every usage of the month value assumes that 1 equals 
# January and 12 equals December.
class Month
	# Returns an array of the full names of months (in English). Note that
	# "January" is the 0th element, and December is the 11th element.
	def Month.monthNames
    [ "January", "February", "March", "April", "May", "June", "July", "August",
			"September", "October", "November", "December" ]
	end

	include Comparable

	attr_reader :month, :year

	# A new month can be set to a specific month and year, or you can call 
	# Month.new with no arguments to receive the current month.
	def initialize( month = nil, year = nil )
		require 'date'
		if month.nil? || year.nil?
			date = Date.today
			month = date.mon unless month
			year = date.year unless year
		end
		fail "invalid month" if month < 1 || month > 12
		@month = month
		@year = year
	end

	def <=>(anOther)
		if @year == anOther.year
			@month <=> anOther.month
		else
			@year <=> anOther.year
		end
	end

	# Returns a string of the format "January 2001".
	def to_s
		Month.monthNames[@month-1][0..2] + " " + @year.to_s
	end

	def hash
		"#{@year}#{@month}".to_i
	end

	def eql?(anOther)
		self == anOther
	end
	
	# Returns a new Month that is +amountToAdd+ months later.
	def +( amountToAdd )
		( fullYears, remainingMonths ) = amountToAdd.divmod( 12 )
		resultYear = @year + fullYears
		resultMonth = @month + remainingMonths
		if resultMonth > 12
			resultMonth -= 12
			resultYear += 1
		end
		Month.new( resultMonth, resultYear )
	end
	
	# Returns a new Month that is +amountToSubtract+ months earlier.
	def -(amountToSubtract)
		self + (-amountToSubtract)
	end
	
	# Returns the previous Month.
	def prev
		self - 1
	end
	
	# Returns the next Month.
	def next
		self + 1
	end
	
	# Returns the first Date of the month.
	def startDate
		Date.new( @year, @month, 1 )
	end
	
	# Returns the last Date of the month.
	def endDate
		self.next.startDate - 1
	end
end
