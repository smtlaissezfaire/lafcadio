require 'lafcadio/test/LafcadioTestCase'
require 'lafcadio/objectField/DateTimeField'

class TestDateTimeField < LafcadioTestCase
	def setup
		super
		@dateTimeField = DateTimeField.new nil, "datetime"
		@aug24 = Time.local (2002, "aug", 24, 13, 8, 22)
	end

	def testValueFromSQL
		value = @dateTimeField.valueFromSQL '20020824130822', false
		assert_equal Time, value.type
		assert_equal @aug24, value
		assert_nil @dateTimeField.valueFromSQL nil
		value2 = @dateTimeField.valueFromSQL '2002-08-24 13:08:22'
		assert_equal value2, @aug24
		oct6 = Time.local (2002, "oct", 6, 0, 0, 0)
		assert_equal oct6, @dateTimeField.valueFromSQL '2002-10-06 00:00:00'
		assert_equal nil, @dateTimeField.valueFromSQL '0000-00-00 00:00:00'
	end

	def testValueForSQL
		assert_equal "'2002-08-24 13:08:22'", @dateTimeField.valueForSQL (@aug24)
		assert_equal "null", @dateTimeField.valueForSQL(nil)
	end
	
	def testValueFromSqlThrowsInformativeError
		begin
			@dateTimeField.valueFromSQL '2002-13-30 01:01:01'
			fail 'should throw an ArgumentError'
		rescue ArgumentError
			assert_not_nil $!.to_s =~ /2002-13-30/, $!.to_s
		end
	end
end
