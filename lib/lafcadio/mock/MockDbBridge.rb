module Lafcadio
	class MockDbBridge
		attr_reader :lastPkIdInserted, :retrievalsByType

		def initialize
			@objects = {}
			@retrievalsByType = Hash.new 0
		end

		def addObject(dbObject)
			commit dbObject
		end

		def commit(dbObject)
			objectsByObjectType = @objects[dbObject.objectType]
			unless objectsByObjectType
				objectsByObjectType = {}
				@objects[dbObject.objectType] = objectsByObjectType
			end
			if dbObject.delete
				objectsByObjectType.delete dbObject.pkId
			else
				object_pkId = dbObject.pkId
				unless object_pkId
					maxpkId = 0
					objectsByObjectType.keys.each { |pkId|
						maxpkId = pkId if pkId > maxpkId
					}
					@lastPkIdInserted = maxpkId + 1
					object_pkId = @lastPkIdInserted
				end
				objectsByObjectType[object_pkId] = dbObject
			end
		end
		
		def collection(objectType, objects); objects; end

		def _getAll(objectType)
			@retrievalsByType[objectType] = @retrievalsByType[objectType] + 1
			@objects[objectType] ? @objects[objectType].values : []
		end

		def getCollectionByQuery(query)
			objectType = query.objectType
			condition = query.condition
			objects = []
			_getAll( objectType ).each { |dbObj|
				if condition
					objects << dbObj if condition.objectMeets(dbObj)
				else
					objects << dbObj
				end
			}
			coll = collection( objectType, objects )
			if (range = query.limit)
				coll = coll[0..(range.last - range.first)]
			end
			coll
		end

		def getMax(objectType)
			max = nil
			@objects[objectType].keys.each { |pkId|
				max = pkId if !max || pkId > max
			}
			max
		end
	end
end
