require 'lafcadio/util'
require 'lafcadio/test'

class TestClass < LafcadioTestCase
	def testGetClass
		assert_equal Class,(Class.get_class('Class'))
		begin
			Class.get_class( 'not-a-class' )
			fail "Should raise MissingError"
		rescue MissingError
			assert_equal( $!.to_s, "Couldn't find class \"not-a-class\"" )
		end
	end
end