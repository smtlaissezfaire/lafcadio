require 'lafcadio/util/ContextualService'

module Lafcadio
	class ObjectStore < ContextualService
		# Caches domain objects for the ObjectStore.
		class Cache
			def initialize( dbBridge )
				@dbBridge = dbBridge
				@objects = {}
				@collections_by_query = {}
			end

			def hashByObjectType(objectType)
				unless @objects[objectType]
					@objects[objectType] = {}
				end
				@objects[objectType]
			end

			# Returns a cached domain object, or nil if none is found.
			def get(objectType, pkId)
				hashByObjectType(objectType)[pkId]
			end

			# Saves a domain object.
			def save(dbObject)
				hashByObjectType(dbObject.objectType)[dbObject.pkId] = dbObject
				flush_collection_cache( dbObject.objectType )
			end
			
			def getByQuery( query )
				unless @collections_by_query[query]
					newObjects = @dbBridge.getCollectionByQuery(query)
					newObjects.each { |dbObj| save dbObj }
					@collections_by_query[query] = newObjects.collect { |dobj|
						dobj.pkId
					}
				end
				collection = []
				@collections_by_query[query].each { |pkId|
					dobj = get( query.objectType, pkId )
					collection << dobj if dobj
				}
				collection
			end

			# Returns an array of all domain objects of a given type.
			def getAll(objectType)
				hashByObjectType(objectType).values
			end

			# Flushes a domain object.
			def flush(dbObject)
				hashByObjectType(dbObject.objectType).delete dbObject.pkId
				flush_collection_cache( dbObject.objectType )
			end
			
			def flush_collection_cache( objectType )
				@collections_by_query.keys.each { |query|
					if query.objectType == objectType
						@collections_by_query.delete( query )
					end
				}
			end
		end
	end
end