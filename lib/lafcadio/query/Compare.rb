require 'lafcadio/query/Condition'

module Lafcadio
	class Query
		# Compares numeric fields.
		class Compare < Condition
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

			def initialize(fieldName, searchTerm, objectType, compareType)
				super fieldName, searchTerm, objectType
				@compareType = compareType
			end

			def toSql
				useFieldForSqlValue = false
				if @fieldName != @objectType.sqlPrimaryKeyName
					field = getField
					useFieldForSqlValue = true unless field.class <= LinkField
				end
				if useFieldForSqlValue
					"#{ dbFieldName } #{ @@comparators[@compareType] } " +
							field.valueForSQL(@searchTerm).to_s
				else
					"#{ dbFieldName } #{ @@comparators[@compareType] } #{ @searchTerm }"
				end
			end

			@@mockComparators = {
				LESS_THAN => Proc.new { |d1, d2| d1 < d2 },
				LESS_THAN_OR_EQUAL => Proc.new { |d1, d2| d1 <= d2 },
				GREATER_THAN_OR_EQUAL => Proc.new { |d1, d2| d1 >= d2 },
				GREATER_THAN => Proc.new { |d1, d2| d1 > d2 }
			}

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
