require 'lafcadio/objectField/MoneyFieldViewer'
require 'lafcadio/objectField/DecimalField'
require 'lafcadio/util/StrUtil'

class MoneyField < DecimalField
	def MoneyField.viewerType
		MoneyFieldViewer
	end

  def initialize (objectType, name, englishName = nil)
    super (objectType, name, 2, englishName)
  end

  def valueAsHTML (dbObject)
    floatValue = super dbObject
    floatValue != nil ? "$" + StrUtil.floatFormat(floatValue, 2) : ""
  end
end