class Query
	class Condition
		def Condition.searchTermType
			Object
		end

		attr_reader :objectType

		def initialize (fieldName, searchTerm, objectType)
			require 'lafcadio/domain/DomainObject'

			@fieldName = fieldName
			@searchTerm = searchTerm
			unless @searchTerm.type <= self.type.searchTermType
				raise "Incorrect searchTerm type #{ searchTerm.type }"
			end
			@objectType = objectType
			if @objectType
				unless @objectType <= DomainObject
					raise "Incorrect object type #{ @objectType.to_s }"
				end
			end
		end
	end
end