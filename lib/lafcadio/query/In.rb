require 'lafcadio/query/Condition'

module Lafcadio
	class Query
		class In < Condition #:nodoc:
			def In.searchTermType
				Array
			end

			def toSql
				"#{ dbFieldName } in (#{ @searchTerm.join(', ') })"
			end

			def objectMeets(anObj)
				value = anObj.send @fieldName
				@searchTerm.index(value) != nil
			end
		end
	end
end