require 'lafcadio/htmlUtil/DateWidget'
require 'lafcadio/objectField/FieldViewer'

class DateFieldViewer < FieldViewer
  def toHTMLWidget (fieldType = @field.type)  
		require 'lafcadio/objectField/MonthField'
		widget = DateWidget.new(@field.name, @value)
		widget.showDomSelect = false if fieldType <= MonthField
		widget.textEntryYear = true if @field.range == DateField::RANGE_PAST
		widget.toHTML
	end
end
