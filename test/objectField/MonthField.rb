require 'lafcadio/test'
require 'lafcadio/objectField'

class TestMonthField < LafcadioTestCase
	def setup
		super
		@field = MonthField.new nil, "expirationDate"
	end

	def testVerifyMonths
		@field.verify((Month.new(12, 2005)), nil)
		caught = false
		begin
			@field.verify(Date.new(5, 12, 2005))
		rescue
			caught = true
		end
		assert caught
	end

	def testValueForSQL
		assert_equal("'2005-12-01'", @field.value_for_sql(Month.new(12, 2005)))
	end
end