require 'lafcadio/util/ContextualService'

module Lafcadio
	class ObjectStore < ContextualService
		class Cache #:nodoc:
			def initialize( dbBridge )
				@dbBridge = dbBridge
				@objects = {}
				@collections_by_query = {}
				@commit_times = {}
			end

			def hashByObjectType(objectType)
				unless @objects[objectType]
					@objects[objectType] = {}
				end
				@objects[objectType]
			end

			# Returns a cached domain object, or nil if none is found.
			def get(objectType, pkId)
				hashByObjectType(objectType)[pkId].clone
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
				hashByObjectType(objectType).values.collect { |d_obj| d_obj.clone }
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

			def last_commit_time( domain_class, pkId )
				by_domain_class = @commit_times[domain_class]
				by_domain_class ? by_domain_class[pkId] : nil
			end
			
			def set_commit_time( d_obj )
				by_domain_class = @commit_times[d_obj.objectType]
				if by_domain_class.nil?
					by_domain_class = {}
					@commit_times[d_obj.objectType] = by_domain_class
				end
				by_domain_class[d_obj.pkId] = Time.now
			end
		end
	end
end
