require 'runit/testcase'
require 'lafcadio/html/Strong'

class TestStrong < RUNIT::TestCase
	def testToHTML
		strong = HTML::Strong.new "test"
		assert_equal "<strong>test</strong>", strong.toHTML
	end
end