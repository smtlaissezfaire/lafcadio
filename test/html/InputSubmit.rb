require 'runit/testcase'
require 'lafcadio/html/InputSubmit'

class TestInputSubmit < RUNIT::TestCase
	def testToHTML
		is = HTML::InputSubmit.new
		html = is.toHTML
	end
end