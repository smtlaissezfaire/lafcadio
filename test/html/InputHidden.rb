require 'runit/testcase'
require 'lafcadio/html/InputHidden'

class TestInputHidden < RUNIT::TestCase
	def testToHTML
		ih = HTML::InputHidden.new ({ 'name' => 'invisible' })
		html = ih.toHTML
		assert_not_nil html.index("type='hidden'")
		assert_not_nil html.index("<input ")
	end
end