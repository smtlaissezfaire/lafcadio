require 'lafcadio/test/LafcadioTestCase'
require 'test/mock/domain/User'
require 'test/mock/domain/Invoice'
require 'test/mock/domain/Client'

class TestEquals < LafcadioTestCase
	def testEqualsByFieldType
		equals = Query::Equals.new ('email', 'john.doe@email.com', User)
		assert_equal "email = 'john.doe@email.com'", equals.toSql
		equals2 = Query::Equals.new ('date', Date.new(2003, 1, 1), Invoice)
		assert_equal "date = '2003-01-01'", equals2.toSql
	end

	def testNullClause
		equals = Query::Equals.new ('date', nil, Invoice)
		assert_equal 'date is null', equals.toSql
	end

	def testObjId
		equals = Query::Equals.new ('objId', 123, Client)
		assert_equal 'objId = 123', equals.toSql
	end
end