require 'lafcadio/html/TR'
require 'lafcadio/html/TD'
require 'lafcadio/html/Input'
require 'lafcadio/util/StrUtil'
require 'lafcadio/html/Strong'

class FieldViewer
  def initialize (value, field, objId)
    @value = value
    @field = field
    @objId = objId
  end

  def HTMLWidgetValueStr
    @value
  end

  def toHTMLWidget
		input = HTML::Input.new({ 'name' => @field.name,
															'value' => self.HTMLWidgetValueStr,
															'size' => textBoxSize })
		input.toHTML
  end

  def textBoxSize
    25
  end

  def toHTMLRow (rightContent, label = @field.englishName)
    leftContent = @field.hideLabel ? "" : label.downcase + ":"
    if leftContent == "" && (rightContent == "" || rightContent == nil)
      nil
    else
      row = HTML::TR.new ({ 'bgcolor' => "#ffffff" })
			row.valign = 'top'
			labelCellArgs = { 'valign' => 'top', 'align' => 'right' }
			labelCellArgs['class'] = 'tableCellBold' if leftContent != ""
      row << HTML::TD.new ( labelCellArgs, leftContent)
      row << HTML::TD.new ({ 'class' => 'tableCell', 'valign' => 'top' },
					rightContent)
      row
    end
  end

  def toDisplayRow
    if !@field.hideDisplay
      toHTMLRow self.HTMLWidgetValueStr
    else
      nil
    end
  end

  def aeFormRowRightCell
    if @field.writeOnce && @objId != nil
      self.HTMLWidgetValueStr
    else
      toHTMLWidget
    end
  end

  def toAeFormRows
		if !@field.hideDisplay
      row = toHTMLRow aeFormRowRightCell
      [row]
    else
      []
    end
  end
end
