require 'runit/testcase'
require 'lafcadio/html/TD'
require 'lafcadio/html/Input'
require 'lafcadio/html/Table'
require 'lafcadio/html/Strong'

class TestTR < RUNIT::TestCase
  def setup
    @tr = HTML::TR.new
    @tr << 1
    @tr << 2
    @html = @tr.toHTML
  end

  def testHeaderRow
    assert_nil @html.index("<strong>")
  end

  def testCloseTag
    assert_not_nil @html.index("</tr>")
  end

  def testValign
    tr = HTML::TR.new
    tr << 1
    tr.valign = "top"
    assert_not_nil tr.toHTML.index("valign='top'")
  end

	def testAddsTD
		tr = HTML::TR.new
		tr << 'a'
		assert_not_nil tr.toHTML.index("<td>a</td>")
	end

	def testContainsTD
		tr = HTML::TR.new
		tr <<(HTML::TD.new( {}, "text"))
		html = tr.toHTML
		assert_not_nil html.index("<td")
		assert_not_nil html.index("text")
	end

	def testOtherElement
		tr = HTML::TR.new
		tr << HTML::Input.new({ 'name' => "name", 'value' => "value" })
		html = tr.toHTML
		assert_not_nil html.index("<td><input"), html
	end

	def testToTDF
		tr = HTML::TR.new
		tr << 1
		tr << 2
		assert_equal "1\t2", tr.toTDF
		tr << HTML::Strong.new(3)
		assert_equal "1\t2\t3", tr.toTDF
	end

	def testCustomTD
		tr = HTML::TR.new
		tr << "<td class='myclass'>Content</td>"
		assert_nil tr.toHTML.index("<td><td")
	end

	def testTableAsCellContents
		tr = HTML::TR.new
		tr << "label"
		tr << HTML::Table.new
		html = tr.toHTML
		assert_not_nil html.index("<td><table")
		tr2 = HTML::TR.new
		tr2 << "<table><tr><td></td></tr></table>"
		html2 = tr2.toHTML
		assert_not_nil html2.index("<td><table")
	end
end
