require 'lafcadio/query/Condition'

module Lafcadio
	class Query
		class Equals < Condition #:nodoc:
			def toSql
				sql = "#{ dbFieldName } "
				unless @searchTerm.nil?
					sql += "= " + r_val_string
				else
					sql += "is null"
				end
				sql
			end

			def r_val_string
				if primaryKeyField?
					@searchTerm.to_s
				else
					field = getField
					if @searchTerm.class <= ObjectField
						@searchTerm.db_table_and_field_name
					else
						field.valueForSQL(@searchTerm).to_s
					end
				end
			end

			def objectMeets(anObj)
				if @fieldName == @objectType.sqlPrimaryKeyName
					object_value = anObj.pkId
				else
					object_value = anObj.send @fieldName
				end
				compare_value =
				if @searchTerm.class <= ObjectField
					compare_value = anObj.send( @searchTerm.name )
				else
					compare_value = @searchTerm
				end
				compare_value == object_value
			end
		end
	end
end
