require 'lafcadio/test'
require 'lafcadio/objectField'

class TestDateTimeField < LafcadioTestCase
	def setup
		super
		@dateTimeField = DateTimeField.new nil, "datetime"
		@aug24 = Time.local(2002, "aug", 24, 13, 8, 22)
	end

	def testValueForSQL
		assert_equal "'2002-08-24 13:08:22'",(@dateTimeField.valueForSQL(@aug24))
		assert_equal "null", @dateTimeField.valueForSQL(nil)
	end

	def testValueFromSQL
		ts1 = DBI::Timestamp.new( 2002, 8, 24, 13, 8, 22 )
		value = @dateTimeField.valueFromSQL ts1, false
		assert_equal Time, value.class
		assert_equal @aug24, value
		assert_nil(@dateTimeField.valueFromSQL(nil))
		oct6 = Time.local(2002, "oct", 6, 0, 0, 0)
		dbi_oct6 = DBI::Timestamp.new( 2002, 10, 6 )
		assert_equal oct6,(@dateTimeField.valueFromSQL dbi_oct6)
		assert_equal nil,(@dateTimeField.valueFromSQL nil)
	end
end
