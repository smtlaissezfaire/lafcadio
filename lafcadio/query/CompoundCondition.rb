require 'lafcadio/query/Condition'

module Lafcadio
	class Query
		# Turns two or more conditions into one condition, joined by either AND or 
		# OR.
		class CompoundCondition < Condition
			AND = 1
			OR  = 2
		
			# CompoundCondition takes a list of conditions as its arguments during
			# initialization:
			#   adultMaleCondition = Query::CompoundCondition.new(
			#                            maleCondition, 
			#                            adultCondition )
			# If you want to change the compound type from its default AND to OR, use 
			# that as the last argument:
			#   adultOrMaleCondition = Query::CompoundCondition.new (
			#                              maleCondition,
			#                              adultCondition, 
			#                              Query::CompoundCondition::OR )
			def initialize(*conditions)
				if( [ AND, OR ].index(conditions.last) )
					@compoundType = conditions.last
					conditions.pop
				else
					@compoundType = AND
				end
				@conditions = conditions
				@objectType = conditions[0].objectType
			end

			def toSql
				booleanString = @compoundType == AND ? 'and' : 'or'
				subSqlStrings = @conditions.collect { |cond| cond.toSql }
				"(#{ subSqlStrings.join(" #{ booleanString } ") })"
			end

			def objectMeets(anObj)
				if @compoundType == AND
					om = true
					@conditions.each { |cond| om = om && cond.objectMeets(anObj) }
					om
				else
					om = false
					@conditions.each { |cond| om = om || cond.objectMeets(anObj) }
					om
				end
			end
		end
	end
end
