require 'lafcadio/query/Condition'

module Lafcadio
	class Query
		# Tests a link field against a given domain object.
		class Link < Condition
			def Link.searchTermType
				DomainObject
			end

			def toSql
				"#{ dbFieldName } = #{ @searchTerm.objId }"
			end

			def objectMeets(anObj)
				value = anObj.send @fieldName
				value ? value.objId == @searchTerm.objId : false
			end
		end
	end
end