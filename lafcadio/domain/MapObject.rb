require 'lafcadio/domain/DomainObject'

module Lafcadio
	# Any domain class that is used mostly to map between two other domain 
	# classes should be a subclass of MapObject. Subclasses of MapObject should 
	# override MapObject.mappedTypes, returning a two-element array containing 
	# the domain classes that the map object maps between.
	class MapObject < DomainObject
		# Given one domain class, returns the other domain class that this map 
		# object maps to.
		def MapObject.otherMappedType(firstType)
			types = mappedTypes
			if types.index(firstType) == 0
				types[1]
			else
				types[0]
			end
		end

		def MapObject.subsidiaryMap
			nil
		end
	end
end