require 'lafcadio/test/LafcadioTestCase'
require 'lafcadio/objectField/DecimalField'

class TestDecimalFieldViewer < LafcadioTestCase
  def testDecimalFieldSize
    odf = DecimalField.new(nil, "hours", 2)
		html = odf.viewer('', nil).toHTMLWidget
    assert(html.index("size='6'") != nil)
  end

  def testDecimalPrecision 
    odf = DecimalField.new(nil, "hours", 2)
		html = odf.viewer(1, nil).toHTMLWidget
    assert_not_nil(html.index("value='1.00'"), html)
  end
end