require 'lafcadio/test/LafcadioTestCase'

class TestClassUtil < LafcadioTestCase
	def testGetObjectTypeFromString
		assert_equal Class, ClassUtil.getObjectTypeFromString ('Invoice').type
		assert_equal Class, ClassUtil.getObjectTypeFromString ('Domain::LineItem').
				type
		begin
			assert_equal nil, ClassUtil.getObjectTypeFromString ('notAnObjectType')
			fail "Should throw an error when matching fails"
		rescue CouldntMatchObjectTypeError
			# ok
		end
	end
	
	def testGetClass
		assert_equal ClassUtil, ClassUtil.getClass ('ClassUtil')
	end
end