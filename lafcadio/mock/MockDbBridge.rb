require 'lafcadio/objectStore/Collection'

class MockDbBridge
	attr_reader :lastObjIdInserted, :retrievalsByType

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
			objectsByObjectType.delete dbObject.objId
		else
			unless dbObject.objId
				maxObjId = 0
				objectsByObjectType.keys.each { |objId|
					maxObjId = objId if objId > maxObjId
				}
				@lastObjIdInserted = maxObjId + 1
				dbObject.objId = @lastObjIdInserted
			end
			objectsByObjectType[dbObject.objId] = dbObject
		end
  end
	
	def collection(objectType, objects)
		coll = Collection.new objectType
		coll = coll.concat objects
		coll
	end

	def _getAll(objectType)
		@retrievalsByType[objectType] = @retrievalsByType[objectType] + 1
		coll = Collection.new objectType
		coll = coll.concat(@objects[objectType].values) if @objects[objectType]
		coll
	end

	def getCollectionByQuery(query)
		objectType = query.objectType
		condition = query.condition
		objects = _getAll(objectType).filter { |dbObj|
			if condition
				condition.objectMeets(dbObj)
			else
				true
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
		@objects[objectType].keys.each { |objId|
			max = objId if !max || objId > max
		}
		max
	end
end

