require 'lafcadio/test/LafcadioTestCase'
require 'lafcadio/objectField/EnumField'
require 'test/objectField/EnumField'

class TestEnumFieldViewer < LafcadioTestCase
  def testEnumWidget
		enumField = EnumField.new nil, "number", [ 1, 2, 3 ]
		rightCell = enumField.viewer(1, nil).aeFormRowRightCell
		assert_not_nil rightCell.index(
				"<input type='radio' name='number' value='1' checked>")
  end

	def testTenOrMoreGetsASelect
		enumField = EnumField.new nil, "number", [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ]
		rightCell = enumField.viewer(1, nil).aeFormRowRightCell
		assert_not_nil rightCell.index("<select")
	end
	
	def testNullableFieldGetsBlankSelect
		enumField = EnumField.new nil, "number", [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ]
		enumField.notNull = false
		rightCell = enumField.viewer(1, nil).aeFormRowRightCell
		assert_not_nil rightCell =~ /<option value=''><\/option>/
	end

	def testEnumWidget
		viewer = TestEnumField.getTestEnumField.viewer(nil, nil)
		widget = viewer.toHTMLWidget
		assert_not_nil widget.index("radio"), widget
		assert_not_nil widget.index("name='cardType' value='AX'> " +
				"American Express\n")
		assert_not_nil widget.index("<br>")
	end
end
