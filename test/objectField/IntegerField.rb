require 'lafcadio/test'
require 'lafcadio/objectField'

class TestIntegerField < LafcadioTestCase
	def testValueFromSQL
		field = IntegerField.new nil, "number"
		assert_equal Fixnum, field.value_from_sql("1").class
		field.notNull = false
		assert_equal nil, field.value_from_sql(nil)
	end
end
