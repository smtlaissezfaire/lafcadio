require 'lafcadio/dateTime'
require 'lafcadio/test'

class TestMonth < LafcadioTestCase
	def setup
		@jan2000 = Month.new 2000, 1
		@dec2000 = Month.new 2000, 12
		@jan2001 = Month.new 2001, 1
	end

	def testArithmetic
		assert_equal( Month.new( 2000, 2 ), @jan2000 + 1 )
		assert_equal( Month.new( 2001, 1 ), @jan2000 + 12 )
		assert_equal( Month.new( 1999, 10 ), @jan2000 - 3 )
		assert_equal( Month.new( 1999, 10 ), @jan2000 + -3 )
	end
	
	def testChecksMonth
		caught = false
		begin
			Month.new 1, 2000
		rescue
			caught = true
		end
		assert caught
		Month.new 2000, 1
	end

	def testCompare
		assert @jan2000 < @jan2001
	end

	def testDefaultInitToCurrentMonth
		month = Month.new
		date = Date.today
		assert_equal( date.mon, month.month )
		assert_equal( date.year, month.year )
	end
	
	def testHashable
		newJan2000 = Month.new( 2000, 1 )
		assert_equal @jan2000, newJan2000
		assert_equal @jan2000.hash, newJan2000.hash
		assert( @jan2000.eql?( newJan2000 ) )
		normalHash = {}
		normalHash[@jan2000] = 'q'
		assert_equal 'q', normalHash[newJan2000]
	end

	def testPrevNext
		assert_equal( @dec2000, @jan2001.prev )
		assert_equal( @jan2001, @dec2000.next )
		assert_equal( @jan2000, @jan2000.prev.next )
	end

	def testStartDateAndEndDate
		assert_equal( Date.new( 2000, 12, 1 ), @dec2000.start_date )
		assert_equal( Date.new( 2000, 12, 31 ), @dec2000.end_date )
		assert_equal( Date.new( 1999, 2, 28 ), Month.new( 1999, 2 ).end_date )
	end

	def testTo_s
		assert_equal 'Jan 2000', @jan2000.to_s
	end
end