require 'lafcadio/query/Condition'

class Query
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

		def initialize (fieldName, searchTerm, objectType, compareType)
			super fieldName, searchTerm, objectType
			@compareType = compareType
		end

		def toSql
			useFieldForSqlValue = false
			if @fieldName != @objectType.sqlPrimaryKeyName
				field = getField
				useFieldForSqlValue = true unless field.type <= LinkField
			end
			if useFieldForSqlValue
				"#{ @fieldName } #{ @@comparators[@compareType] } " +
						field.valueForSQL(@searchTerm).to_s
			else
				"#{ @fieldName } #{ @@comparators[@compareType] } #{ @searchTerm }"
			end
		end

		@@mockComparators = {
			LESS_THAN => Proc.new { |d1, d2| d1 < d2 },
			LESS_THAN_OR_EQUAL => Proc.new { |d1, d2| d1 <= d2 },
			GREATER_THAN_OR_EQUAL => Proc.new { |d1, d2| d1 >= d2 },
			GREATER_THAN => Proc.new { |d1, d2| d1 > d2 }
		}

		def objectMeets (anObj)
			value = anObj.send @fieldName
			value = value.objId if value.type <= DomainObject
			value ? @@mockComparators[@compareType].call(value, @searchTerm) : false
		end
	end
end

