require 'lafcadio/test/LafcadioTestCase'
require 'lafcadio/query/Compare'
require 'lafcadio/query/Equals'
require 'date'
require 'test/mock/domain/User'
require 'test/mock/domain/Invoice'
require 'lafcadio/query/CompoundCondition'

class TestCompoundCondition < LafcadioTestCase
	def testCompareAndBooleanEquals		
		pastExpDate = Query::Compare.new('date',
				Date.new(2003, 1, 1), Invoice,
				Query::Compare::GREATER_THAN_OR_EQUAL)
		notExpiredYet = Query::Equals.new('hours', 10, Invoice)
		condition = Query::CompoundCondition.new(pastExpDate, notExpiredYet)
		assert_equal "(date >= '2003-01-01' and hours = 10)", condition.toSql
		assert_equal Invoice, condition.objectType
	end

	def testMoreThanTwoConditions
		pastExpDate = Query::Compare.new('date',
				Date.new(2003, 1, 1), Invoice,
				Query::Compare::GREATER_THAN_OR_EQUAL)
		notExpiredYet = Query::Equals.new('rate', 10, Invoice)
		notComplementary = Query::Equals.new(
				'hours', 10, Invoice)
		condition = Query::CompoundCondition.new(
				pastExpDate, notExpiredYet, notComplementary)
		assert_equal "(date >= '2003-01-01' and rate = 10 and " +
				"hours = 10)", condition.toSql
		invoice = Invoice.new ({ 'objId' => 1, 'date' => Date.new(2003, 1, 1),
				'rate' => 10, 'hours' => 10 })
		assert condition.objectMeets(invoice)
		invoice.hours = 10.5
		assert !condition.objectMeets(invoice)
	end

	def testOr
		email = Query::Equals.new ('email', 'test@test.com', User)
		fname = Query::Equals.new ('firstNames', 'John', User)
		user = User.getTestUser
		assert email.objectMeets(user)
		assert !fname.objectMeets(user)
		compound = Query::CompoundCondition.new (email, fname,
				Query::CompoundCondition::OR)
		assert_equal "(email = 'test@test.com' or firstNames = 'John')",
				compound.toSql
		assert compound.objectMeets(user)
	end
end