module Lafcadio
	class SqlValueConverter #:nodoc:
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
