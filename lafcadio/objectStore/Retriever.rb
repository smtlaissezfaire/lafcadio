require 'lafcadio/util/ContextualService'
require 'lafcadio/query/Query'

class ObjectStore < ContextualService
	class Retriever
		def initialize (dbBridge)
			require 'lafcadio/objectStore/Cache'
			@dbBridge = dbBridge
			@cache = ObjectStore::Cache.new
			@objectTypesFullyRetrieved = []
		end

		def get (objectType, objId)
			require 'lafcadio/objectStore/DomainObjectNotFoundError'
			raise "ObjectStore.getObject can't accept nil objId" if objId == nil
			objId = objId.to_i
			if objId.type != Fixnum
				raise "ObjectStore.getObject needs a Fixnum as its objId, " +
						"objId is #{objId} (#{objId.type})"
			end
			unless @cache.get (objectType, objId)
				query = Query.new objectType, objId
				dbObject = @dbBridge.getCollectionByQuery(query)[0]
				@cache.save dbObject if dbObject
			end
			(@cache.get (objectType, objId)) || (raise (DomainObjectNotFoundError,
					"Can't find #{objectType} #{objId}", caller))
		end

		def getAll (objectType)
			require 'lafcadio/objectStore/Collection'
			unless @objectTypesFullyRetrieved.index(objectType)
				@objectTypesFullyRetrieved << objectType
				query = Query.new objectType
				newObjects = @dbBridge.getCollectionByQuery(query)
				newObjects.each { |dbObj| @cache.save dbObj }
			end
			coll = Collection.new(objectType)
			coll.concat(@cache.getAll objectType)
		end

		def flush (dbObject)
			@cache.flush dbObject
		end

		def clear (dbObject)
			@cache.flush dbObject
		end

		def set (dbObject)
			@cache.save dbObject
		end
	end
end

