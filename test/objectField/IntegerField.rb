require 'lafcadio/test/LafcadioTestCase'
require 'lafcadio/objectField/IntegerField'

class TestIntegerField < LafcadioTestCase
	def testValueFromSQL
		field = IntegerField.new nil, "number"
		assert_equal Fixnum, field.valueFromSQL("1").type
		field.notNull = false
		assert_equal nil, field.valueFromSQL(nil)
	end
end
