require 'lafcadio'

module Lafcadio
	# The ObjectStore represents the database in a Lafcadio application.
	#
	# There are a few important dynamic method names used by ObjectStore:
	#
	# [ObjectStore#get< domain class > (objId)]
	#   Retrieves one domain object by objId. For example,
	#     ObjectStore#getUser (100)
	#   will return User 100.
	# [ObjectStore#get< domain class >s (searchTerm, fieldName = nil)]
	#   Looks for instances of that domain class matching that search term. For
	#   example,
	#     ObjectStore#getProducts (aProductCategory)
	#   queries MySQL for all products that belong to that product category. If 
	#   <tt>fieldName</tt> isn't given, it's inferred from the 
	#   <tt>searchTerm</tt>. This works well for a search term that is a domain 
	#   object, but for something more prosaic you'll probably need to set 
	#   <tt>fieldName</tt> explicitly:
	#     ObjectStore#getUsers ("Jones", "lastName")
	class ObjectStore < ContextualService
		def ObjectStore.setDbName(dbName)
			DbBridge.setDbName dbName
		end
		
		def initialize(context, dbBridge = nil)
			super context
			@dbBridge = dbBridge == nil ? DbBridge.new : dbBridge
			@cache = ObjectStore::Cache.new
			@objectTypesFullyRetrieved = []
		end

		def clear(dbObject)
			@cache.flush dbObject
		end

		# Commits a domain object to the database. You can also simply call
		#   myDomainObject.commit
		def commit(dbObject)
			require 'lafcadio/objectStore/Committer'
			committer = Committer.new dbObject, @dbBridge
			committer.execute
			updateCacheAfterCommit( committer )
		end
		
		# Flushes one domain object from its cache.
		def flush(dbObject)
			@cache.flush dbObject
		end

		# Returns the domain object corresponding to the domain class and objId.
		def get(objectType, objId)
			require 'lafcadio/objectStore/DomainObjectNotFoundError'
			raise "ObjectStore.getObject can't accept nil objId" if objId == nil
			objId = objId.to_i
			if objId.class != Fixnum
				raise "ObjectStore.getObject needs a Fixnum as its objId, " +
						"objId is #{objId}(#{objId.class})"
			end
			unless @cache.get(objectType, objId)
				query = Query.new objectType, objId
				dbObject = @dbBridge.getCollectionByQuery(query)[0]
				@cache.save dbObject if dbObject
			end
			(@cache.get(objectType, objId)) ||(raise(DomainObjectNotFoundError,
					"Can't find #{objectType} #{objId}", caller))
		end

		# Returns all domain objects for the given domain class.
		def getAll(objectType)
			unless @objectTypesFullyRetrieved.index(objectType)
				@objectTypesFullyRetrieved << objectType
				query = Query.new objectType
				newObjects = @dbBridge.getCollectionByQuery(query)
				newObjects.each { |dbObj| @cache.save dbObj }
			end
			@cache.getAll(objectType)
		end

		def getDbBridge; @dbBridge; end

		def getFiltered(objectTypeName, searchTerm, fieldName = nil)
			require 'lafcadio/query/Link'
			objectType = DomainObject.getObjectTypeFromString objectTypeName
			unless fieldName
				fieldName = searchTerm.objectType.bareName
				fieldName = fieldName.decapitalize
			end
			if searchTerm.class <= DomainObject
				condition = Query::Link.new(fieldName, searchTerm, objectType)
			else
				condition = Query::Equals.new(fieldName, searchTerm, objectType)
			end
			getSubset( condition )
		end

		def getMapMatch(objectType, mapped)
			fieldName = mapped.objectType.bareName.decapitalize
			Query::Equals.new(fieldName, mapped, objectType)
		end

		def getMapObject(objectType, map1, map2)
			require 'lafcadio/query/CompoundCondition'
			unless map1 && map2
				raise ArgumentError,
						"ObjectStore#getMapObject needs two non-nil keys", caller
			end
			mapMatch1 = getMapMatch objectType, map1
			mapMatch2 = getMapMatch objectType, map2
			condition = Query::CompoundCondition.new mapMatch1, mapMatch2
			getSubset(condition)[0]
		end

		def getMapped(searchTerm, resultTypeName)
			resultType = DomainObject.getObjectTypeFromString resultTypeName
			coll = []
			firstTypeName = searchTerm.class.bareName
			secondTypeName = resultType.bareName
			mapTypeName = firstTypeName + secondTypeName
			getFiltered(mapTypeName, searchTerm).each { |mapObj|
				coll << mapObj.send( resultType.name.decapitalize )
			}
			coll
		end
		
		def getMax( domain_class ); @dbBridge.getMax( domain_class ); end

		def getObjects(objectType, objIds)
			require 'lafcadio/query/In'
			condition = Query::In.new('objId', objIds, objectType)
			getSubset condition
		end

		# Returns a collection of domain objects that correspond to the Condition 
		# or Query. This queries the database for only the relevant objects, and
		# as such can offer significant time savings over retrieving all the 
		# objects and then filtering them in Ruby.
		def getSubset(conditionOrQuery)
			if conditionOrQuery.class <= Query::Condition
				condition = conditionOrQuery
				query = Query.new condition.objectType, condition
			else
				query = conditionOrQuery
			end
			@dbBridge.getCollectionByQuery query
		end

		def method_missing(methodId, *args)
			proc = block_given? ? ( proc { |obj| yield( obj ) } ) : nil
			dispatch = MethodDispatch.new( methodId, proc, *args )
			self.send( dispatch.symbol, *dispatch.args )
		end
		
		# Caches one domain object.
		def set(dbObject)
			@cache.save dbObject
		end
		
		def updateCacheAfterCommit( committer )
			if committer.commitType == Committer::UPDATE ||
				committer.commitType == Committer::INSERT
				set( committer.dbObject )
			elsif committer.commitType == Committer::DELETE
				clear( committer.dbObject )
			end
		end
	end
end
