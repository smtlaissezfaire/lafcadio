require 'lafcadio/dateTime'
require 'lafcadio/test'

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
		assert( @jan2000.eql?( newJan2000 ) )
		normalHash = {}
		normalHash[@jan2000] = 'q'
		assert_equal 'q', normalHash[newJan2000]
	end
	
	def testDefaultInitToCurrentMonth
		month = Month.new
		date = Date.today
		assert_equal( date.mon, month.month )
		assert_equal( date.year, month.year )
	end
	
	def testArithmetic
		assert_equal( Month.new( 2, 2000 ), @jan2000 + 1 )
		assert_equal( Month.new( 1, 2001 ), @jan2000 + 12 )
		assert_equal( Month.new( 10, 1999 ), @jan2000 - 3 )
		assert_equal( Month.new( 10, 1999 ), @jan2000 + -3 )
	end
	
	def testPrevNext
		assert_equal( @dec2000, @jan2001.prev )
		assert_equal( @jan2001, @dec2000.next )
		assert_equal( @jan2000, @jan2000.prev.next )
	end
	
	def testStartDateAndEndDate
		assert_equal( Date.new( 2000, 12, 1 ), @dec2000.startDate )
		assert_equal( Date.new( 2000, 12, 31 ), @dec2000.endDate )
		assert_equal( Date.new( 1999, 2, 28 ), Month.new( 2, 1999 ).endDate )
	end
end