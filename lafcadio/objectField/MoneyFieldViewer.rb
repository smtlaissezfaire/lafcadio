require 'lafcadio/objectField/DecimalFieldViewer'

class MoneyFieldViewer < DecimalFieldViewer
  def toHTMLWidget
     "$ " + super
  end
end