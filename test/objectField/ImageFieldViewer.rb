require 'lafcadio/test/LafcadioTestCase'
require 'lafcadio/objectField/ImageField'

class TestImageFieldViewer < LafcadioTestCase
	def setup
		super
		@imgField = ImageField.new nil, "img"
	end

  def testImageWidget
		cell = @imgField.viewer(nil, nil).aeFormRowRightCell
    assert_not_nil cell.index("<input type='file'")
		prevValueCell = @imgField.viewer('john.jpg', nil).aeFormRowRightCell
    assert_not_nil prevValueCell.index(
				"<input name='img.prev' value='john.jpg' type='hidden'>")
  end

	def testCurrentImageHTML
		prevValueCell = @imgField.viewer('john.jpg', nil).currentImageHTML
    assert_not_nil prevValueCell.toHTML.index("<img src='/img/john.jpg'>")
	end

	def testWithSWF
		html = @imgField.viewer('flash.swf', nil).currentImageHTML
		assert_not_nil html.toHTML.index("<object classid=")
	end
end