require 'lafcadio/query/Condition'

module Lafcadio
	class Query
		# Tests a link field against a given domain object.
		class Link < Condition
			def Link.searchTermType
				DomainObject
			end

			def toSql
				"#{ dbFieldName } = #{ @searchTerm.pkId }"
			end

			def objectMeets(anObj)
				value = anObj.send @fieldName
				value ? value.pkId == @searchTerm.pkId : false
			end
		end
	end
end