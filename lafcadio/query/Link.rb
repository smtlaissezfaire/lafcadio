require 'lafcadio/query/Condition'

class Query
	class Link < Condition
		def Link.searchTermType
			DomainObject
		end

		def toSql
			"#{ @fieldName } = #{ @searchTerm.objId }"
		end

		def objectMeets (anObj)
			value = anObj.send @fieldName
			value ? value.objId == @searchTerm.objId : false
		end
	end
end
