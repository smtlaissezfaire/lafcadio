require 'lafcadio/query/Condition'

class Query
	class CompoundCondition < Condition
		def initialize (*conditions)
			@conditions = conditions
			@objectType = conditions[0].objectType
		end

		def toSql
			(@conditions.collect { |cond| cond.toSql }).join(' and ')
		end

		def objectMeets (anObj)
			om = true
			@conditions.each { |cond| om = om && cond.objectMeets(anObj) }
			om
		end
	end
end

