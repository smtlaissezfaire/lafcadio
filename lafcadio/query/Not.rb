require 'lafcadio/query/Condition'

class Query
	class Not < Condition
		def initialize (unCondition)
			@unCondition = unCondition
		end

		def toSql
			"!(#{ @unCondition.toSql })"
		end

		def objectMeets (obj)
			!@unCondition.objectMeets(obj)
		end
	end
end