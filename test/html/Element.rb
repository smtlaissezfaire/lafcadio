require 'runit/testcase'
require 'lafcadio/html/Element'

class TestElement < RUNIT::TestCase
	def testTagName
		assert_equal "element", HTML::Element.tagName
	end
end