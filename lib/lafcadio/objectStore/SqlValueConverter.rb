module Lafcadio
	# Turns a hash of SQL key-value pairs into Ruby-native key-value pairs.
	class SqlValueConverter
		attr_reader :objectType, :rowHash

		def initialize(objectType, rowHash)
			@objectType = objectType
			@rowHash = rowHash
		end

		def []( key )
			if key == 'pkId'
				@rowHash[@objectType.sqlPrimaryKeyName].to_i
			else
				begin
					field = @objectType.getField( key )
					field.valueFromSQL( @rowHash[ key ] )
				rescue MissingError
					nil
				end
			end
		end
	end
end
