require 'lafcadio/util/ContextualService'

module Lafcadio
	class ObjectStore < ContextualService
		# Caches domain objects for the ObjectStore.
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

			# Returns a cached domain object, or nil if none is found.
			def get(objectType, objId)
				hashByObjectType(objectType)[objId]
			end

			# Saves a domain object.
			def save(dbObject)
				hashByObjectType(dbObject.objectType)[dbObject.objId] = dbObject
			end

			# Returns an array of all domain objects of a given type.
			def getAll(objectType)
				hashByObjectType(objectType).values
			end

			# Flushes a domain object.
			def flush(dbObject)
				hashByObjectType(dbObject.objectType).delete dbObject.objId
			end
		end
	end
end
