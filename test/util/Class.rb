require 'lafcadio/util'
require 'lafcadio/test/LafcadioTestCase'

class TestClass < LafcadioTestCase
	def testGetClass
		assert_equal Class,(Class.getClass('Class'))
		begin
			Class.getClass( 'not-a-class' )
			fail "Should raise MissingError"
		rescue MissingError
			assert_equal( $!.to_s, "Couldn't find class \"not-a-class\"" )
		end
	end
end