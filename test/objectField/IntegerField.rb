require 'lafcadio/test/LafcadioTestCase'
require 'lafcadio/objectField'

class TestIntegerField < LafcadioTestCase
	def testValueFromSQL
		field = IntegerField.new nil, "number"
		assert_equal Fixnum, field.valueFromSQL("1").class
		field.notNull = false
		assert_equal nil, field.valueFromSQL(nil)
	end
end
