require 'lafcadio/objectField/FieldViewer'

class DecimalFieldViewer < FieldViewer
  def HTMLWidgetValueStr
    if @value != nil && @value != ""
      StrUtil.floatFormat(@value, @field.precision)
    else
      @value
    end
  end

  def textBoxSize
    6
  end
end