require 'lafcadio/test/LafcadioTestCase'
require 'lafcadio/util/DomainUtil'

class TestDomainUtil < LafcadioTestCase
	def testGetObjectTypeFromString
		assert_equal Class,((DomainUtil.getObjectTypeFromString('Invoice')).class)
		assert_equal Class,(
				(DomainUtil.getObjectTypeFromString('Domain::LineItem')).class)
		begin
			assert_equal nil,(DomainUtil.getObjectTypeFromString('notAnObjectType'))
			fail "Should throw an error when matching fails"
		rescue CouldntMatchObjectTypeError
			# ok
		end
		attributeClass = DomainUtil.getObjectTypeFromString( 'Attribute' )
		assert_equal( Class, attributeClass.class )
		assert_equal( 'Attribute', attributeClass.to_s )
	end
end