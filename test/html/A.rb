require 'runit/testcase'
require 'lafcadio/html/A'
require 'lafcadio/html/IMG'

class TestA < RUNIT::TestCase
	def testToHTMLContents
		link = HTML::A.new({ 'href' => 'page.html' })
		link << HTML::IMG.new({ 'src' => 'pic.gif' })
		html = link.toHTML
		assert_not_nil html =~ /<img src='pic.gif'>/
		assert_not_nil html =~ /<a href='page.html'>/
		link << "Some string"
		html = link.toHTML
		assert_not_nil html =~ /Some string/
		assert_not_nil html.index("</a>")
	end

	def testNoNewLinesWithOneElement
		link = HTML::A.new({ 'href' => 'page.html' }, 'text' )
		html = link.toHTML
		assert_equal "<a href='page.html'>text</a>", html
	end
end