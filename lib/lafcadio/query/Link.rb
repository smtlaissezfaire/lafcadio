require 'lafcadio/query/Condition'

module Lafcadio
	class Query
		class Link < Condition #:nodoc:
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