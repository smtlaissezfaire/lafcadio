require 'runit/testcase'
require 'lafcadio/html/Form'

class TestForm < RUNIT::TestCase
	def testName
		form = HTML::Form.new({ 'action' => "action.rb" })
		assert_nil form.toHTML.index("name='")
		form.name = "ae"
		assert_not_nil form.toHTML.index("name='ae'")
	end

	def testMultipart
		form = HTML::Form.new({ 'action' => "action.rb" })
		assert_nil form.toHTML.index("enctype='")
		form.multipart = true
		assert_not_nil form.toHTML.index("enctype='multipart/form-data'")
	end

	def testAction
		form = HTML::Form.new({ 'action' => "action.rb" })
		assert_not_nil form.toHTML.index("action='action.rb'")
		adminForm = HTML::Form.new({ 'action' => 'admin/action.rb' })
		assert_not_nil adminForm.toHTML.index("action='admin/action.rb'")
	end

	def testMethod
		form = HTML::Form.new({ 'action' => "action.rb" })
		assert_not_nil form.toHTML.index("method='post'")
		form = HTML::Form.new({ 'action' => 'action.rb', 'method' => 'get' })
		assert_not_nil form.toHTML.index("method='get'")
	end
end