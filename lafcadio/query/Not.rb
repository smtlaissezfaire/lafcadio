require 'lafcadio/query/Condition'

class Query
	# Returns the opposite of a given condition.
	class Not < Condition
		def initialize(unCondition)
			@unCondition = unCondition
		end

		def toSql
			"!(#{ @unCondition.toSql })"
		end

		def objectMeets(obj)
			!@unCondition.objectMeets(obj)
		end
		
		def objectType; @unCondition.objectType; end
	end
end