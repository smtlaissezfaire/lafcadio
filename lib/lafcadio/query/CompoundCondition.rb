require 'lafcadio/query/Condition'

module Lafcadio
	class Query
		class CompoundCondition < Condition #:nodoc:
			AND = 1
			OR  = 2
		
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

			def objectMeets(anObj)
				if @compoundType == AND
					@conditions.inject( true ) { |result, cond|
						result && cond.objectMeets( anObj )
					}
				else
					@conditions.inject( false ) { |result, cond|
						result || cond.objectMeets( anObj )
					}
				end
			end

			def toSql
				booleanString = @compoundType == AND ? 'and' : 'or'
				subSqlStrings = @conditions.collect { |cond| cond.toSql }
				"(#{ subSqlStrings.join(" #{ booleanString } ") })"
			end
		end
	end
end
