require 'runit/testcase'
require 'lafcadio/html/HTML'

class TestHTML < RUNIT::TestCase
	def testAddP
		html = HTML.new "line1"
		html.addP
		html << "line2"
		assert_not_nil html.toHTML.index("<p>")
	end

	def testHandlesNil
		html = HTML.new "line1"
		html << nil
		assert_equal "line1\n", html.toHTML
	end

	def testFirstEltOptional
		html = HTML.new
		html << "line1"
		assert_equal "line1\n", html.toHTML
	end
end