require 'test/objectField/EnumField'
require 'lafcadio/objectField/MonthField'
require 'lafcadio/test/LafcadioTestCase'
require 'lafcadio/objectField/ObjectField'
require 'lafcadio/objectField/DateField'
require 'lafcadio/objectField/SortOrderField'

class TestFieldViewer < LafcadioTestCase
  def setup
  	super
    @dateField = DateField.new nil
  end

	def genericField
		ObjectField.new nil, 'fieldName'
	end

  def testHideLabel
		field = genericField
    field.hideLabel = true
		viewer = field.viewer('content', nil)
    html = viewer.toDisplayRow.toHTML
    assert_nil html.index("fieldName"), html
		assert_nil html =~ /class='tableCellBold'/
  end

  def testWriteOnce
		field = genericField
    field.writeOnce = true
		viewer = field.viewer('test@test.com', 1)
    html = viewer.toAeFormRows[0].toHTML
    assert_nil html.index("input"), html
    assert_not_nil html.index("test@test.com")
		html2 = field.viewer('test@test.com', nil).toAeFormRows[0].toHTML
		assert_not_nil html2 =~ /<input /
  end

  def testHideDisplay
		field = genericField
    field.hideDisplay = true
		viewer = field.viewer(false, nil)
    assert_nil viewer.toDisplayRow
    assert_equal(0, viewer.toAeFormRows.size)
  end

  def testToAeFormRow
		field = genericField
		viewer = field.viewer('Francis', nil)
    html = viewer.toAeFormRows[0].toHTML
    assert_not_nil html.index("input")
		assert_not_nil html.index("valign='top'")
		assert_not_nil html.index("bgcolor='#ffffff'"), html
  end

  def testWidgetValuesSet
    dateValue = Date.new(2001, 10, 24)
		widget = @dateField.viewer(dateValue, nil).toHTMLWidget
    assert_not_nil(widget.index(
	"<option value='10' selected>October</option>"))
    assert_not_nil(widget.index("<option value='24' selected>24</option>"))
    assert_not_nil(widget.index("<option value='2001' selected>2001</option>"))
  end
  
  def testDateRangeYear
		widgetNearFuture = @dateField.viewer(nil, nil).toHTMLWidget
		yearStr = Date.today.year.to_s
		assert_not_nil widgetNearFuture =~ /#{yearStr}/, widgetNearFuture
		@dateField.range = DateField::RANGE_PAST
		widgetPast = @dateField.viewer(nil, nil).toHTMLWidget
		assert_not_nil widgetPast =~ /<input name='date.year'/, widgetPast
  end

	def testNoAeFormRowsForSortOrderField
		sortOrderField = SortOrderField.new nil
		viewer = sortOrderField.viewer(1, nil)
		assert_equal 0, viewer.toAeFormRows.size
	end

	def testMonthWidget
		monthField = MonthField.new(nil, "expirationDate",
				"Expiration date")
		viewer = monthField.viewer(nil, nil)
		widget = viewer.toHTMLWidget
		assert_not_nil widget.index("<select name='expirationDate.month'"),
				widget
		assert_not_nil widget.index("<select name='expirationDate.year'"), widget
		currentYear = Date.today.year
		assert_not_nil widget.index("<option value='#{currentYear}'>" +
				"#{currentYear}</option>"), widget
		assert_nil widget =~ /expirationDate.dom/		
	end
end
