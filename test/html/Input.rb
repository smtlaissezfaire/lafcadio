require 'runit/testcase'
require 'lafcadio/html/Input'

class TestInput < RUNIT::TestCase
  def testToHTML
    input = HTML::Input.new({ 'name' => "n", 'value' => "v", 'size' => 4 })
    html = input.toHTML
		assert_not_nil html.index("<input")
		assert_not_nil html.index("name='n'")
		assert_not_nil html.index("size='4'")
		assert_not_nil html.index("value='v'")
  end
end