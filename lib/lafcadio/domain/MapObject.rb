require 'lafcadio/domain/DomainObject'

module Lafcadio
	# Any domain class that is used mostly to map between two other domain 
	# classes should be a subclass of MapObject. Subclasses of MapObject should 
	# override MapObject.mappedTypes, returning a two-element array containing 
	# the domain classes that the map object maps between.
	class MapObject < DomainObject
		def MapObject.otherMappedType(firstType) #:nodoc:
			types = mappedTypes
			if types.index(firstType) == 0
				types[1]
			else
				types[0]
			end
		end

		def MapObject.subsidiaryMap #:nodoc:
			nil
		end
	end
end