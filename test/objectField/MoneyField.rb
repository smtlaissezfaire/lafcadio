require 'lafcadio/test'
require '../test/mock/domain/Client'

class TestMoneyField < LafcadioTestCase
	def testNilToNull
    omf = MoneyField.new nil, "standard_rate"
		assert_equal String, omf.value_for_sql(nil).class
		assert_equal 'null', omf.value_for_sql(nil)
	end
end