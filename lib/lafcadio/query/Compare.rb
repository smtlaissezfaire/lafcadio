require 'lafcadio/query/Condition'

module Lafcadio
	class Query
		class Compare < Condition #:nodoc:
			LESS_THAN							= 1
			LESS_THAN_OR_EQUAL		= 2
			GREATER_THAN_OR_EQUAL = 3
			GREATER_THAN					= 4

			@@comparators = {
				LESS_THAN => '<',
				LESS_THAN_OR_EQUAL => '<=',
				GREATER_THAN_OR_EQUAL => '>=',
				GREATER_THAN => '>'
			}

			@@mockComparators = {
				LESS_THAN => Proc.new { |d1, d2| d1 < d2 },
				LESS_THAN_OR_EQUAL => Proc.new { |d1, d2| d1 <= d2 },
				GREATER_THAN_OR_EQUAL => Proc.new { |d1, d2| d1 >= d2 },
				GREATER_THAN => Proc.new { |d1, d2| d1 > d2 }
			}

			def initialize(fieldName, searchTerm, objectType, compareType)
				super fieldName, searchTerm, objectType
				@compareType = compareType
			end

			def toSql
				useFieldForSqlValue = ( @fieldName != @objectType.sqlPrimaryKeyName &&
				                        !( getField.class <= LinkField ) )
				search_val = ( useFieldForSqlValue ?
				               getField.valueForSQL(@searchTerm).to_s :
				               @searchTerm.to_s )
				"#{ dbFieldName } #{ @@comparators[@compareType] } " + search_val
			end

			def objectMeets(anObj)
				value = anObj.send @fieldName
				value = value.pkId if value.class <= DomainObject
				if value
					@@mockComparators[@compareType].call(value, @searchTerm)
				else
					false
				end
			end
		end
	end
end
