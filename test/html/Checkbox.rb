require 'runit/testcase'
require 'lafcadio/html/Checkbox'

class TestCheckbox < RUNIT::TestCase
	def testToHTML
		checkbox = HTML::Checkbox.new ({ 'name' => 'checkbox' })
		assert_equal HTML::Checkbox, checkbox.type
		html = checkbox.toHTML
		assert_not_nil html.index(" type='checkbox'"), html
		checkbox.checked = true
		html = checkbox.toHTML
		assert_nil html.index("checked='"), html
		assert_not_nil html.index("checked")
	end
end