require 'lafcadio/test/LafcadioTestCase'
require 'lafcadio/html/Strong'
require 'lafcadio/htmlUtil/HeaderRow'

class TestHeaderRow < LafcadioTestCase
	def testToHTML
		row = HeaderRow.new
		row << "a"
		row << "b"
		html = row.toHTML
		assert_not_nil html.index("<td><strong>a</strong></td>"), html
		row << HTML::TD.new({ 'colspan' => 2 }, 'c')
		html = row.toHTML
		assert_not_nil html.index("<td colspan='2'><strong>c</strong></td>"), html
	end

	def testNonBreakingSpaces
		row = HeaderRow.new
		row << "Shipping address"
		html = row.toHTML
		assert_not_nil html.index("Shipping&nbsp;address")
	end

	def testOnlyAcceptStringsAndTDs
		row = HeaderRow.new
		row << "a"
		caught = false
		begin
			row <<(HTML::Strong.new('b'))
		rescue
			caught = true
		end
		assert caught
		row <<(HTML::TD.new({ 'colspan' => 2 }, 'c'))
	end

	def testInitWithArray
		row = HeaderRow.new({}, [ 'a', 'b' ])
		html = row.toHTML
		assert_not_nil html =~ /<td><strong>a<\/strong><\/td>/
		assert_not_nil html =~ /<td><strong>b<\/strong><\/td>/
	end
end