require 'lafcadio/dateTime/DateTimeUtil'
require 'lafcadio/test/LafcadioTestCase'

class TestDateTimeUtil < LafcadioTestCase
	def testTimeToDate
		now = Time.now
		today = Date.today
		assert_equal today, DateTimeUtil.timeToDate(now)
		assert_nil DateTimeUtil.timeToDate(nil)
	end

	def testDateToTime
		today = Date.today
		time = DateTimeUtil.dateToTime today
		assert_equal today.year, time.year
		assert_equal today.month, time.month
		assert_equal today.day, time.day
		assert_nil DateTimeUtil.dateToTime(nil)
	end
end