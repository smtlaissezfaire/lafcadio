require 'lafcadio/test/LafcadioTestCase'

class TestClassUtil < LafcadioTestCase
	def testGetClass
		assert_equal ClassUtil, ClassUtil.getClass ('ClassUtil')
	end
end