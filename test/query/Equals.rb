require 'lafcadio/test'
require '../test/mock/domain/User'
require '../test/mock/domain/Invoice'
require '../test/mock/domain/InternalClient'
require '../test/mock/domain/Client'

class TestEquals < LafcadioTestCase
	def testEqualsByFieldType
		equals = Query::Equals.new('email', 'john.doe@email.com', User)
		assert_equal( "users.email = 'john.doe@email.com'", equals.to_sql )
		equals2 = Query::Equals.new('date', Date.new(2003, 1, 1), Invoice)
		assert_equal( "invoices.date = '2003-01-01'", equals2.to_sql )
	end

	def testNullClause
		equals = Query::Equals.new('date', nil, Invoice)
		assert_equal( 'invoices.date is null', equals.to_sql )
	end

	def testPkId
		equals = Query::Equals.new('pk_id', 123, Client)
		assert_equal( 'clients.pk_id = 123', equals.to_sql )
	end

	def testSubclass
		clientCondition = Query::Equals.new('name', 'client 1', InternalClient)
		assert_equal( "clients.name = 'client 1'", clientCondition.to_sql )
	end
	
	def testBooleanField
		equals = Query::Equals.new( 'administrator', false, User )
		assert_equal( 'users.administrator = 0', equals.to_sql )
	end
	
	def testDbFieldName
		equals = Query::Equals.new( 'text1', 'foobar', XmlSku )
		assert_equal( "some_other_table.text_one = 'foobar'", equals.to_sql )
	end
	
	def test_compare_to_other_field
		email_field = User.get_field( 'email' )
		equals = Query::Equals.new( 'firstNames', email_field, User )
		assert_equal( 'users.firstNames = users.email', equals.to_sql )
		odd_user = User.new( 'email' => 'foobar', 'firstNames' => 'foobar' )
		assert( equals.object_meets( odd_user ) )
	end
	
	def test_different_pk_name
		equals1 = Query::Equals.new( 'pk_id', 123, XmlSku )
		assert_equal( 'some_other_table.some_other_id = 123', equals1.to_sql )
	end
end