require 'lafcadio/test/LafcadioTestCase'
require '../test/mock/domain/User'
require '../test/mock/domain/Invoice'
require '../test/mock/domain/InternalClient'
require '../test/mock/domain/Client'

class TestEquals < LafcadioTestCase
	def testEqualsByFieldType
		equals = Query::Equals.new('email', 'john.doe@email.com', User)
		assert_equal( "users.email = 'john.doe@email.com'", equals.toSql )
		equals2 = Query::Equals.new('date', Date.new(2003, 1, 1), Invoice)
		assert_equal( "invoices.date = '2003-01-01'", equals2.toSql )
	end

	def testNullClause
		equals = Query::Equals.new('date', nil, Invoice)
		assert_equal( 'invoices.date is null', equals.toSql )
	end

	def testPkId
		equals = Query::Equals.new('pkId', 123, Client)
		assert_equal( 'clients.pkId = 123', equals.toSql )
	end

	def testSubclass
		clientCondition = Query::Equals.new('name', 'client 1', InternalClient)
		assert_equal( "clients.name = 'client 1'", clientCondition.toSql )
	end
	
	def testBooleanField
		equals = Query::Equals.new( 'administrator', false, User )
		assert_equal( 'users.administrator = 0', equals.toSql )
	end
	
	def testDbFieldName
		equals = Query::Equals.new( 'text1', 'foobar', XmlSku )
		assert_equal( "some_other_table.text_one = 'foobar'", equals.toSql )
	end
	
	def test_compare_to_other_field
		email_field = User.getField( 'email' )
		equals = Query::Equals.new( 'firstNames', email_field, User )
		assert_equal( 'users.firstNames = users.email', equals.toSql )
		odd_user = User.new( 'email' => 'foobar', 'firstNames' => 'foobar' )
		assert( equals.objectMeets( odd_user ) )
	end
end