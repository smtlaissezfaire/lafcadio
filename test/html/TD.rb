require 'runit/testcase'
require 'lafcadio/html/Strong'
require 'lafcadio/html/TD'

class TestTD < RUNIT::TestCase
	def testToHTML
		td = HTML::TD.new( {}, 'text' )
		assert_not_nil td.toHTML.index("<td>text</td>")
		td.colspan = 2
		assert_not_nil td.toHTML.index("<td colspan='2'>")
	end

	def testAlign
		td = HTML::TD.new( {}, 'text' )
		assert_nil td.toHTML.index("align")
		td.align = "right"
		assert_not_nil td.toHTML.index("align='right'")
	end

	def testNonStringContents
		td = HTML::TD.new( {},(HTML::Strong.new "text"))
		assert_equal "<td><strong>text</strong></td>", td.toHTML
	end

	def testBgColor
		td = HTML::TD.new( {}, 'text' )
		td.bgcolor = '#000000'
		assert_equal "<td bgcolor='#000000'>text</td>", td.toHTML
	end

	def testContainsTable
		tableStr = '<table><tr><td></td></tr></table>'
		td = HTML::TD.new( {}, tableStr )
		assert_equal "<td>#{tableStr}</td>", td.toHTML
	end

	def testWithClass
		td = HTML::TD.new( { 'class' => 'someclass' }, "contents" )
		assert_equal "<td class='someclass'>contents</td>", td.toHTML
	end
end