require 'lafcadio/test'
require 'lafcadio/query'
require '../test/mock/domain/User'

class TestNot < LafcadioTestCase
	def setup
		super
		@not = Query::Not.new(
				Query::Equals.new('email', 'test@test.com', User))
	end
	
	def test_object_type; assert_equal( User, @not.object_type ); end

	def testToSql
		assert_equal "!(users.email = 'test@test.com')", @not.toSql
	end

	def testObjectsMeets
		user = User.getTestUser
		assert !@not.objectMeets(user)
		user2 = User.new({ 'email' => 'jane.doe@email.com' })
		assert @not.objectMeets(user2)
	end
end