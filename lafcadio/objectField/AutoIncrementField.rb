require 'lafcadio/objectField/IntegerField'

class AutoIncrementField < IntegerField
  attr_reader :objectType

  def initialize(objectType, name, englishName = nil)
    super(objectType, name, englishName)
    @objectType = objectType
  end

  def HTMLWidgetValueStr(value)
    if value != nil
      super value
    else
      highestValue = 0
      ObjectStore.getObjectStore.getAll(objectType).each { |obj|
        aValue = obj.send(name).to_i
        highestValue = aValue if aValue > highestValue
      }
     (highestValue + 1).to_s
    end
  end
end
