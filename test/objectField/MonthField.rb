require 'lafcadio/test/LafcadioTestCase'
require 'lafcadio/mock/MockFieldManager'
require 'lafcadio/objectField/MonthField'

class TestMonthField < LafcadioTestCase
	def setup
		super
		@field = MonthField.new nil, "expirationDate"
	end

	def testValueFromCGI
		fm = MockFieldManager.new ({ 'expirationDate.month' => '12',
																	'expirationDate.year' => '2005' })
		value = @field.valueFromCGI fm
		assert_equal 12, value.month
		assert_equal 2005, value.year
	end

	def testVerifyMonths
		@field.verify (Month.new (12, 2005), nil)
		caught = false
		begin
			@field.verify (Date.new (5, 12, 2005))
		rescue
			caught = true
		end
		assert caught
	end

	def testValueForSQL
		assert_equal "'2005-12-01'", @field.valueForSQL(Month.new 12, 2005)
	end
end