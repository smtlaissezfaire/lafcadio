require 'lafcadio/util/StrUtil'
require 'lafcadio/query/Equals'

class Collector
  def initialize(objectStore = Context.instance.getObjectStore)
		@objectStore = objectStore
  end

	def getFiltered(objectTypeName, searchTerm, fieldName = nil)
		require 'lafcadio/query/Link'
		require 'lafcadio/util/DomainUtil'
		objectType = DomainUtil.getObjectTypeFromString objectTypeName
		unless fieldName
			fieldName = ClassUtil.bareClassName(searchTerm.objectType)
			fieldName = StrUtil.decapitalize fieldName
		end
		if searchTerm.class <= DomainObject
			condition = Query::Link.new(fieldName, searchTerm, objectType)
		else
			condition = Query::Equals.new(fieldName, searchTerm, objectType)
		end
		@objectStore.getSubset condition
	end

	def getMapped(searchTerm, resultTypeName)
		resultType = ClassUtil.getObjectTypeFromString resultTypeName
		coll = ObjectCollection.new resultType
		firstTypeName = ClassUtil.bareClassName searchTerm.class
		secondTypeName = ClassUtil.bareClassName resultType
		mapTypeName = firstTypeName + secondTypeName
		getFiltered(mapTypeName, searchTerm).each { |mapObj|
			coll << mapObj.send(StrUtil.decapitalize(resultType.name))
		}
		coll
	end

	def method_missing(methodId, searchTerm, fieldName = nil)
		require 'lafcadio/util/EnglishUtil'
		methodName = methodId.id2name
		if methodName =~ /^get(.*)$/
			objectTypeName = EnglishUtil.singular($1)
			getFiltered(objectTypeName, searchTerm, fieldName)
		else
			super(methodId)
		end
	end

	def getObjects(objectType, objIds)
		require 'lafcadio/query/In'
		condition = Query::In.new('objId', objIds, objectType)
		@objectStore.getSubset condition
	end

	def getMapMatch(objectType, mapped)
		fieldName = ClassUtil.bareClassName(mapped.objectType)
		fieldName = StrUtil.decapitalize fieldName
		Query::Equals.new(fieldName, mapped, objectType)
	end

	def getMapObject(objectType, map1, map2)
		require 'lafcadio/query/CompoundCondition'
		unless map1 && map2
			raise ArgumentError,
					"Collector#getMapObject needs two non-nil keys", caller
		end
		mapMatch1 = getMapMatch objectType, map1
		mapMatch2 = getMapMatch objectType, map2
		condition = Query::CompoundCondition.new mapMatch1, mapMatch2
		@objectStore.getSubset(condition)[0]
	end
end

