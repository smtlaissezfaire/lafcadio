require 'lafcadio/objectField/DecimalField'
require 'lafcadio/util/StrUtil'

class MoneyField < DecimalField
	def MoneyField.instantiateWithParameters( domainClass, parameters )
		self.new( domainClass, parameters['name'], parameters['englishName'] )
	end

  def initialize(objectType, name, englishName = nil)
    super(objectType, name, 2, englishName)
  end

  def valueAsHTML(dbObject)
    floatValue = super dbObject
    floatValue != nil ? "$" + StrUtil.floatFormat(floatValue, 2) : ""
  end
end