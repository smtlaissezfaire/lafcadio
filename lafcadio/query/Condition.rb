class Query
	# The abstract base class for all the other subconditions. Subclasses need to 
	# define two different methods:
	# [toSql] Returns a string that would be inserted after the word "where" in a 
	#         SQL query.
	# [objectMeets(anObj)] When passed a domain object, returns a boolean value 
	#                      indicating whether that object passed this condition. 
	#                      For use in testing.
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