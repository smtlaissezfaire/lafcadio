# Represents a specific month in time. With the exception of Month.monthNames,
# every usage of the month value assumes that 1 equals January and 12 equals
# December.
class Month
	# Returns an array of the full names of months (in English). Note that
	# "January" is the 0th element, and December is the 11th element.
	def Month.monthNames
    [ "January", "February", "March", "April", "May", "June", "July", "August",
			"September", "October", "November", "December" ]
	end

	include Comparable

	attr_reader :month, :year

	def initialize(month, year)
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
end
