require 'lafcadio/query/Condition'

module Lafcadio
	class Query
		class Link < Condition #:nodoc:
			def self.searchTermType
				DomainObject
			end

			def objectMeets(anObj)
				value = anObj.send @fieldName
				value ? value.pkId == @searchTerm.pkId : false
			end

			def toSql
				"#{ dbFieldName } = #{ @searchTerm.pkId }"
			end
		end
	end
end