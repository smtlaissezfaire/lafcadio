require 'lafcadio/test'
require 'lafcadio/query'
require '../test/mock/domain'

class TestNot < LafcadioTestCase
	def setup
		super
		@not = Query::Not.new(
				Query::Equals.new('email', 'test@test.com', User))
	end
	
	def test_domain_class; assert_equal( User, @not.domain_class ); end

	def testToSql
		assert_equal "!(users.email = 'test@test.com')", @not.to_sql
	end

	def testObjectsMeets
		user = User.getTestUser
		assert !@not.object_meets(user)
		user2 = User.new({ 'email' => 'jane.doe@email.com' })
		assert @not.object_meets(user2)
	end
end