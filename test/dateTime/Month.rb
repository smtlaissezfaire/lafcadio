require 'lafcadio/dateTime/Month'
require 'lafcadio/test/LafcadioTestCase'

class TestMonth < LafcadioTestCase
	def setup
		@jan2000 = Month.new 1, 2000
		@dec2000 = Month.new 12, 2000
		@jan2001 = Month.new 1, 2001
	end

	def testChecksMonth
		caught = false
		begin
			Month.new 2000, 1
		rescue
			caught = true
		end
		assert caught
		Month.new 1, 2000
	end

	def testCompare
		assert @jan2000 < @jan2001
	end

	def testTo_s
		assert_equal 'Jan 2000', @jan2000.to_s
	end

	def testHashable
		newJan2000 = Month.new(1, 2000)
		assert_equal @jan2000, newJan2000
		assert_equal @jan2000.hash, newJan2000.hash
		assert @jan2000.eql? newJan2000
		normalHash = {}
		normalHash[@jan2000] = 'q'
		assert_equal 'q', normalHash[newJan2000]
	end
end