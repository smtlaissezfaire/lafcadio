require 'runit/testcase'
require 'lafcadio/html/Select'

class TestSelect < RUNIT::TestCase
  def testNoOnChange
    select = HTML::Select.new({ 'name' => "name" })
    assert_nil select.toHTML.index("onChange=\"")
  end

  def testSelected
    select = HTML::Select.new({ 'name' => 'month' })
		select.selected = 2
    select.addOption(1, "January")
    select.addOption(2, "February")
    html = select.toHTML
    assert_nil html.index("<option value='1' selected>January</option>")
    assert_not_nil html.index("<option value='2' selected>February</option>")
  end

	def testAddOption
		select = HTML::Select.new({ 'name' => "year" })
		select.selected = 2010
		select.addOption 2002
		html = select.toHTML
		assert_not_nil html.index("<option value='2002'>2002</option>")
	end
end