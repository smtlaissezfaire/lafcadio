require 'lafcadio/domain/DomainObject'

class MapObject < DomainObject
	def MapObject.otherMappedType (firstType)
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
