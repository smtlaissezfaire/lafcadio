module Lafcadio
	class SqlValueConverter #:nodoc:
		attr_reader :objectType, :rowHash

		def initialize(objectType, rowHash)
			@objectType = objectType
			@rowHash = rowHash
		end

		def []( key )
			if key == 'pkId'
				if ( field_val = @rowHash[@objectType.sqlPrimaryKeyName] ).nil?
					raise FieldMatchError, error_msg, caller
				else
					field_val.to_i
				end
			else
				begin
					field = @objectType.getField( key )
					field.valueFromSQL( @rowHash[ key ] )
				rescue MissingError
					nil
				end
			end
		end

		def error_msg
			"The field \"" + @objectType.sqlPrimaryKeyName +
					"\" can\'t be found in the table \"" + 
					@objectType.tableName + "\"."
		end
	end
end
