require 'lafcadio/objectField/ObjectField'

class TextListField < ObjectField
	def valueFromSQL (sqlString, lookupLink = true)
		if sqlString
			sqlString.split ','
		else
			[]
		end
	end

	def valueForSQL (objectValue)
		"'" + objectValue.join(',') + "'"
	end
end