require 'lafcadio/test/LafcadioTestCase'
require 'lafcadio/query/Equals'
require 'test/mock/domain/User'
require 'lafcadio/query/Not'

class TestNot < LafcadioTestCase
	def setup
		super
		@not = Query::Not.new(
				Query::Equals.new('email', 'test@test.com', User))
	end

	def testToSql
		assert_equal "!(email = 'test@test.com')", @not.toSql
	end

	def testObjectsMeets
		user = User.getTestUser
		assert !@not.objectMeets(user)
		user2 = User.new({ 'email' => 'jane.doe@email.com' })
		assert @not.objectMeets(user2)
	end
end