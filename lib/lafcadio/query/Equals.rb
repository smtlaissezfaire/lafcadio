require 'lafcadio/query/Condition'

module Lafcadio
	class Query
		# Tests whether a field is equal to a given value.
		class Equals < Condition
			def toSql
				sql = "#{ dbFieldName } "
				unless @searchTerm.nil?
					sql += "= "
					if @fieldName == @objectType.sqlPrimaryKeyName
						sql += @searchTerm.to_s
					else
						field = getField
						sql += field.valueForSQL(@searchTerm).to_s
					end
				else
					sql += "is null"
				end
				sql
			end

			def objectMeets(anObj)
				if @fieldName == @objectType.sqlPrimaryKeyName
					value = anObj.objId
				else
					value = anObj.send @fieldName
				end
				@searchTerm == value
			end
		end
	end
end
