require 'lafcadio/objectStore/ObjectStore'

module Lafcadio
	class MockDbBridge #:nodoc:
		attr_reader :lastPkIdInserted, :retrievalsByType, :query_count

		def initialize
			@objects = {}
			@retrievalsByType = Hash.new 0
			@query_count = Hash.new( 0 )
		end

		def addObject(dbObject)
			commit dbObject
		end

		def commit(dbObject)
			objectsByObjectType = get_objects_by_domain_class( dbObject.objectType )
			if dbObject.delete
				objectsByObjectType.delete dbObject.pkId
			else
				object_pkId = get_pkId_before_committing( dbObject )
				objectsByObjectType[object_pkId] = dbObject
			end
		end
		
		def _getAll(objectType)
			@retrievalsByType[objectType] = @retrievalsByType[objectType] + 1
			@objects[objectType] ? @objects[objectType].values : []
		end
		
		def getCollectionByQuery(query)
			@query_count[query] += 1
			objects = []
			_getAll( query.objectType ).each { |dbObj|
				if query.condition
					objects << dbObj if query.condition.objectMeets(dbObj)
				else
					objects << dbObj
				end
			}
			if (range = query.limit)
				objects = objects[0..(range.last - range.first)]
			end
			objects
		end
		
		def get_pkId_before_committing( dbObject )
			object_pkId = dbObject.pkId
			unless object_pkId
				maxpkId = 0
				get_objects_by_domain_class( dbObject.objectType ).keys.each { |pkId|
					maxpkId = pkId if pkId > maxpkId
				}
				@lastPkIdInserted = maxpkId + 1
				object_pkId = @lastPkIdInserted
			end
			object_pkId
		end
		
		def get_objects_by_domain_class( domain_class )
			objects_by_domain_class = @objects[domain_class]
			unless objects_by_domain_class
				objects_by_domain_class = {}
				@objects[domain_class] = objects_by_domain_class
			end
			objects_by_domain_class
		end

		def group_query( query )
			if query.class == Query::Max
				query.collect( @objects[query.objectType].values )
			end
		end
	end

	# Externally, the MockObjectStore looks and acts exactly like the ObjectStore,
	# but stores all its data in memory. This makes it very useful for unit
	# testing, and in fact LafcadioTestCase#setup creates a new instance of
	# MockObjectStore for each test case.
	class MockObjectStore < ObjectStore
		public_class_method :new

		def initialize(context) # :nodoc:
			super(context, MockDbBridge.new)
		end

		def addObject(dbObject) # :nodoc:
			commit dbObject
		end
	end
end
