require 'lafcadio/query/Condition'

module Lafcadio
	class Query
		class Not < Condition #:nodoc:
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
end