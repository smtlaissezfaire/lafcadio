require 'lafcadio/objectField/FieldViewer'

class TextFieldViewer < FieldViewer
  def toHTMLWidget
    if @field.large
      "<textarea name='#{@field.name}' cols='50' rows='8'>" +
	  "#{self.HTMLWidgetValueStr}</textarea>"
    else
      super
    end
  end
end
