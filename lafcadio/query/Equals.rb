require 'lafcadio/query/Condition'

class Query
	class Equals < Condition
		def toSql
			sql = "#{ @fieldName } "
			if @searchTerm != nil
				sql += "= "
				if @fieldName == @objectType.sqlPrimaryKeyName
					sql += @searchTerm.to_s
				else
					field = @objectType.getField @fieldName
					sql += field.valueForSQL(@searchTerm).to_s
				end
			else
				sql += "is null"
			end
			sql
		end

		def objectMeets (anObj)
			if @fieldName == @objectType.sqlPrimaryKeyName
				value = anObj.objId
			else
				value = anObj.send @fieldName
			end
			@searchTerm == value
		end
	end
end

