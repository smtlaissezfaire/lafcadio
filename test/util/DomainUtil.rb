require 'lafcadio/test/LafcadioTestCase'
require 'lafcadio/util/DomainUtil'

class TestDomainUtil < LafcadioTestCase
	def testGetObjectTypeFromString
		assert_equal Class, DomainUtil.getObjectTypeFromString ('Invoice').type
		assert_equal Class, DomainUtil.getObjectTypeFromString ('Domain::LineItem').
				type
		begin
			assert_equal nil, DomainUtil.getObjectTypeFromString ('notAnObjectType')
			fail "Should throw an error when matching fails"
		rescue CouldntMatchObjectTypeError
			# ok
		end
	end
end