require 'runit/testcase'
require 'lafcadio/html/Table'
require 'lafcadio/html/TR'

class TestTable < RUNIT::TestCase
  def testCloseTag
    assert_not_nil HTML::Table.new.toHTML.index("</table>")    
  end

  def testBgColor
    html = HTML::Table.new({ 'bgcolor' => "#cccccc"}).toHTML
    assert_not_nil html.index("bgcolor='#cccccc'")
  end

	class TRChild < HTML::TR
	end

  def testChecksElements
    caught = false
    table = HTML::Table.new
    begin
      table << "string"
    rescue
      caught = true
    end
    assert caught
    table << HTML::TR.new
    assert_equal(1, table.size)
		table << TRChild.new
		form = HTML::Form.new({ 'action' => '/cgi-bin/action.rb' })
		table << form
  end

  def testHandleNil
    table = HTML::Table.new
    table << nil
  end

	def testNumColumns
		table = HTML::Table.new
		row1 = HTML::TR.new
		row1 << "a"
		row1 << "b"
		table << row1
		row2 = HTML::TR.new
		row2 << "c"
		row2 << "d"
		row2 << "e"
		table << row2
		assert_equal 3, table.numColumns
	end

	def testNoBorder
		table = HTML::Table.new
		assert_nil table.toHTML.index("border")
	end

	def testInsertColumn
		table = HTML::Table.new
		row1 = HTML::TR.new
		row1 << "a"
		row1 << "b"
		table << row1
		row2 = HTML::TR.new
		row2 << "c"
		row2 << "d"
		table << row2
		assert_equal "a", table[0][0]
		assert_equal "c", table[1][0]
		table.insertColumn
		assert_equal "", table[0][0]
		assert_equal "", table[1][0]
		assert_equal "a", table[0][1]
		assert_equal "c", table[1][1]
	end

	def testToTDF
		table = HTML::Table.new
		row1 = HTML::TR.new
		row1 << 'a'
		row1 << 'b'
		table << row1
		assert_equal "a\tb", table.toTDF
	end

	def testToHTML
		table = HTML::Table.new
		row1 = HTML::TR.new
		row1 << 'a'
		row1 << 'b'
		table << row1
		html = table.toHTML
		assert_not_nil html.index("</td>\n"), html
	end
end
