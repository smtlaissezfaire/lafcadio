require 'lafcadio/query/Condition'

module Lafcadio
	class Query
		class In < Condition #:nodoc:
			def self.searchTermType
				Array
			end

			def objectMeets(anObj)
				value = anObj.send @fieldName
				@searchTerm.index(value) != nil
			end

			def toSql
				"#{ dbFieldName } in (#{ @searchTerm.join(', ') })"
			end
		end
	end
end