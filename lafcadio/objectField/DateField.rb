require 'lafcadio/objectField/ObjectField'
require 'date'
require 'lafcadio/objectField/DateFieldViewer'

class DateField < ObjectField
	RANGE_NEAR_FUTURE = 0
	RANGE_PAST = 1

  def DateField.valueType
    Date
  end

  def DateField.viewerType
    DateFieldViewer
  end

	attr_accessor :range

  def initialize(objectType, name = "date", englishName = nil)
    super(objectType, name, englishName)
		@range = RANGE_NEAR_FUTURE
  end

  def valueFromCGI(fieldManager)
    fieldManager.getDate name
  end

  def valueForSQL(value)
		value ? "'#{value.to_s}'" : 'null'
  end

  def valueFromSQL(string, lookupLink = true)
		if string != nil
	    dateFields = string.split("-")
  	  year = dateFields[0].to_i
    	month = dateFields[1].to_i
	    dom = dateFields[2].to_i
  	  if year != 0 && month != 0 && dom != 0
    	  Date.new(year, month, dom)
	    else
  	    nil
    	end
		else
			nil
		end
  end
end

