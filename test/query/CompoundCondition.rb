require 'lafcadio/test'
require 'lafcadio/query'
require 'date'
require '../test/mock/domain'

class TestCompoundCondition < LafcadioTestCase
	def testCompareAndBooleanEquals		
		pastExpDate = Query::Compare.new('date',
				Date.new(2003, 1, 1), Invoice,
				Query::Compare::GREATER_THAN_OR_EQUAL)
		notExpiredYet = Query::Equals.new('hours', 10, Invoice)
		condition = Query::CompoundCondition.new(pastExpDate, notExpiredYet)
		assert_equal( "(invoices.date >= '2003-01-01' and invoices.hours = 10)",
		              condition.to_sql )
		assert_equal Invoice, condition.object_type
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
		assert_equal( "(invoices.date >= '2003-01-01' and invoices.rate = 10 and " +
		              "invoices.hours = 10)",
		              condition.to_sql )
		invoice = Invoice.new({ 'pk_id' => 1, 'date' => Date.new(2003, 1, 1),
				'rate' => 10, 'hours' => 10 })
		assert condition.object_meets(invoice)
		invoice.hours = 10.5
		assert !condition.object_meets(invoice)
	end

	def testOr
		email = Query::Equals.new('email', 'test@test.com', User)
		fname = Query::Equals.new('firstNames', 'John', User)
		user = User.getTestUser
		assert email.object_meets(user)
		assert !fname.object_meets(user)
		compound = Query::CompoundCondition.new(email, fname,
				Query::CompoundCondition::OR)
		assert_equal( "(users.email = 'test@test.com' or " +
		              "users.firstNames = 'John')",
		              compound.to_sql )
		assert compound.object_meets(user)
	end
end