require 'lafcadio/cgi/Redirect'
require 'lafcadio/test/LafcadioTestCase'

class TestRedirect < LafcadioTestCase
	def testToS
		location = Redirect.new "index.rhtml"
		assert_equal "Location: http://test.url/index.rhtml\n\n", location.to_s
		location2 = Redirect.new "index.rhtml", false
		assert_equal "Location: http://test.url/index.rhtml\n", location2.to_s
	end
end
