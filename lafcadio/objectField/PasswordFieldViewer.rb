require 'lafcadio/objectField/FieldViewer'

class PasswordFieldViewer < FieldViewer
  def textBoxSize
    @field.maxLength + 1
  end

  def toDisplayRow
    nil
  end

  def passwordField (num)
    "<input name='#{@field.name}#{num}' value='' size='#{textBoxSize}' " +
	"type='password'>"
  end

  def toAeFormRows
    row1 = toHTMLRow(passwordField(1), "enter password")
    row2 = toHTMLRow(passwordField(2), "re-enter password")
    [ row1, row2 ]
  end
end