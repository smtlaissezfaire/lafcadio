class Query
	class Condition
		def Condition.searchTermType
			Object
		end

		attr_reader :objectType

		def initialize(fieldName, searchTerm, objectType)
			require 'lafcadio/domain/DomainObject'

			@fieldName = fieldName
			@searchTerm = searchTerm
			unless @searchTerm.class <= self.class.searchTermType
				raise "Incorrect searchTerm type #{ searchTerm.class }"
			end
			@objectType = objectType
			if @objectType
				unless @objectType <= DomainObject
					raise "Incorrect object type #{ @objectType.to_s }"
				end
			end
		end
		
		def getField
			anObjectType = @objectType
			field = nil
			while(anObjectType < DomainObject || anObjectType < DomainObject) &&
						!field
				field = anObjectType.getField @fieldName
				anObjectType = anObjectType.superclass
			end
			field
		end
	end
end