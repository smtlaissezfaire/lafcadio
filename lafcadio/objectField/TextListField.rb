require 'lafcadio/objectField/ObjectField'

# TextListField maps to any String SQL field that tries to represent a 
# quick-and-dirty list with a comma-separated string. It returns an Array. For 
# example, a SQL field with the value "john,bill,dave", then the Ruby field will 
# have the value <tt>[ "john", "bill", "dave" ]</tt>.
class TextListField < ObjectField
	def valueFromSQL(sqlString, lookupLink = true)
		if sqlString
			sqlString.split ','
		else
			[]
		end
	end

	def valueForSQL(objectValue)
		"'" + objectValue.join(',') + "'"
	end
end