require 'lafcadio/test/LafcadioTestCase'

class TestClassUtil < LafcadioTestCase
	def testGetClass
		assert_equal ClassUtil,(ClassUtil.getClass('ClassUtil'))
		begin
			ClassUtil.getClass( 'not-a-class' )
			fail "Should raise MissingError"
		rescue MissingError
			assert_equal( $!.to_s, "Couldn't find class \"not-a-class\"" )
		end
	end
end