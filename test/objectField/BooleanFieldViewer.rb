require 'lafcadio/test/LafcadioTestCase'
require 'lafcadio/objectField/BooleanField'

class TestBooleanFieldViewer < LafcadioTestCase
	def testToHTMLWidget
		bf = BooleanField.new nil, "hidden"
		viewer = bf.viewer(true, nil)
		html = viewer.toHTMLWidget
		assert_not_nil html.index('checked')
	end
end