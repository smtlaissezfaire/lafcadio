require 'lafcadio/test/LafcadioTestCase'
require '../test/mock/domain/User'
require '../test/mock/domain/Invoice'
require '../test/mock/domain/InternalClient'
require '../test/mock/domain/Client'

class TestEquals < LafcadioTestCase
	def testEqualsByFieldType
		equals = Query::Equals.new('email', 'john.doe@email.com', User)
		assert_equal "email = 'john.doe@email.com'", equals.toSql
		equals2 = Query::Equals.new('date', Date.new(2003, 1, 1), Invoice)
		assert_equal "date = '2003-01-01'", equals2.toSql
	end

	def testNullClause
		equals = Query::Equals.new('date', nil, Invoice)
		assert_equal 'date is null', equals.toSql
	end

	def testObjId
		equals = Query::Equals.new('objId', 123, Client)
		assert_equal 'objId = 123', equals.toSql
	end

	def testSubclass
		clientCondition = Query::Equals.new('name', 'client 1', InternalClient)
		assert_equal "name = 'client 1'", clientCondition.toSql
	end
	
	def testBooleanField
		equals = Query::Equals.new( 'administrator', false, User )
		assert_equal( 'administrator = 0', equals.toSql )
	end
	
	def testDbFieldName
		equals = Query::Equals.new( 'text1', 'foobar', XmlSku )
		assert_equal( "text_one = 'foobar'", equals.toSql )
	end
end