require 'lafcadio/query/Condition'

module Lafcadio
	class Query
		# Tests whether a field value is in a given range of values.
		class In < Condition
			def In.searchTermType
				Array
			end

			def toSql
				"#{ @fieldName } in (#{ @searchTerm.join(', ') })"
			end

			def objectMeets(anObj)
				value = anObj.send @fieldName
				@searchTerm.index(value) != nil
			end
		end
	end
end