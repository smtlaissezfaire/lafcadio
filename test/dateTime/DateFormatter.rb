require 'date'
require 'lafcadio/dateTime/DateFormatter'
require 'lafcadio/test/LafcadioTestCase'

class TestDateFormatter < LafcadioTestCase
	def setup
		@oct28_2002 = Date.new (2002, 10, 28)
		@nov3_2002 = Date.new (2002, 11, 3)
	end

	def testToS
		formatter = DateFormatter.new ('mm-dd-yyyy')
		assert_equal '10-28-2002', formatter.to_s (@oct28_2002)
		assert_equal '', formatter.to_s (nil)
		assert_equal '11-3-2002', formatter.to_s (@nov3_2002)
	end

	def testMonthName
		formatter = DateFormatter.new ('month dd, yyyy')
		assert_equal '', formatter.to_s (nil)
		assert_equal 'October 28, 2002', formatter.to_s (@oct28_2002)
		assert_equal 'November 3, 2002', formatter.to_s (@nov3_2002)
	end
	
	def testSprintfFormat
		formatter = DateFormatter.new ('%yyyy %02mm %02dd')
		assert_equal '', formatter.to_s (nil)
		assert_equal '2002 10 28', formatter.to_s (@oct28_2002)
		assert_equal '2002 11 03', formatter.to_s (@nov3_2002)
	end
end