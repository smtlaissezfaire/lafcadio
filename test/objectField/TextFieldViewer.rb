require 'lafcadio/test/LafcadioTestCase'
require 'lafcadio/objectField/TextField'

class TestTextFieldViewer < LafcadioTestCase
  def testHiddenLabelAndNoContentEqualsNullRow
    address2Field = TextField.new nil, "address2"
    address2Field.notNull = false
    address2Field.hideLabel = true
		viewer = address2Field.viewer('', nil)
    assert_nil viewer.toDisplayRow
		viewer2 = address2Field.viewer(nil, nil)
    assert_nil viewer2.toDisplayRow
  end

  def testLargeWidgetForLargeText
    tField = TextField.new nil, "description"
    tField.large = true
		widget = tField.viewer(nil, nil).toHTMLWidget
    assert_not_nil widget.index("<textarea name='description'")
  end
end