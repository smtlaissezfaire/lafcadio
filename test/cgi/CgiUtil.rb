require 'lafcadio/test/LafcadioTestCase'
require 'lafcadio/cgi/CgiUtil'

class TestCgiUtil < LafcadioTestCase
	def testPercentSign
		assert_equal 'address=123+Main+Street+%232B',
				CgiUtil.cgiArgString ({ 'address' => '123 Main Street #2B' })
	end
end