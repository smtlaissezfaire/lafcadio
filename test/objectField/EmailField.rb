require 'lafcadio/test/LafcadioTestCase'
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
	end

	def testValidAddress
		assert !EmailField.validAddress('a@a')
		assert !EmailField.validAddress('a.a@a')
		assert !EmailField.validAddress('a.a.a')
		assert !EmailField.validAddress('a')
		assert EmailField.validAddress('a@a.a')
		assert EmailField.validAddress('a,a@a.a')
		assert !EmailField.validAddress('a@a.a, my_friend_too@a.a')
		assert !EmailField.validAddress('cant have spaces @ this. that')
  end
end