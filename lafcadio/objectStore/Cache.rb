require 'lafcadio/util/ContextualService'

class ObjectStore < ContextualService
	class Cache
		def initialize
			@objects = {}
		end

		def hashByObjectType(objectType)
			unless @objects[objectType]
				@objects[objectType] = {}
			end
			@objects[objectType]
		end

		def get(objectType, objId)
			hashByObjectType(objectType)[objId]
		end

		def save(dbObject)
			hashByObjectType(dbObject.objectType)[dbObject.objId] = dbObject
		end

		def getAll(objectType)
			hashByObjectType(objectType).values
		end

		def flush(dbObject)
			hashByObjectType(dbObject.objectType).delete dbObject.objId
		end
	end
end

