require 'lafcadio/objectField/ObjectField'
require 'lafcadio/util/StrUtil'
require 'lafcadio/objectField/DecimalFieldViewer'

class DecimalField < ObjectField
  attr_reader :precision

  def DecimalField.valueType
    Numeric
  end

  def DecimalField.viewerType
    DecimalFieldViewer
  end

  def initialize (objectType, name, precision, englishName = nil)
    super (objectType, name, englishName)
    @precision = precision
  end

  def valueFromSQL (string, lookupLink = true)
    string != nil ? string.to_f : nil
  end

  def processBeforeVerify (value)
    value = super value
    value != nil && value != '' ? value.to_f : nil
  end
end

