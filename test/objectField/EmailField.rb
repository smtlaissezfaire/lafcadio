require 'lafcadio/test'
require '../test/mock/domain/User'

class TestEmailField < LafcadioTestCase
  def testVerify
    field = EmailField.new User
		begin
			field.verify('a@a', nil)
			fail "didn't catch 'a@'"
		rescue FieldValueError
			# ok
		end
		field.not_null = false
		field.verify( nil, 1 )
	end

	def testValidAddress
		assert !EmailField.valid_address('a@a')
		assert !EmailField.valid_address('a.a@a')
		assert !EmailField.valid_address('a.a.a')
		assert !EmailField.valid_address('a')
		assert EmailField.valid_address('a@a.a')
		assert EmailField.valid_address('a,a@a.a')
		assert !EmailField.valid_address('a@a.a, my_friend_too@a.a')
		assert !EmailField.valid_address('cant have spaces @ this. that')
  end
end