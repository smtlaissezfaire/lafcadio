require 'lafcadio/query/Condition'

class Query
	class In < Condition
		def In.searchTermType
			Array
		end

		def toSql
			"#{ @fieldName } in (#{ @searchTerm.join(',') })"
		end

		def objectMeets (anObj)
			value = anObj.send @fieldName
			@searchTerm.index(value) != nil
		end
	end
end