require 'lafcadio/query'
require 'lafcadio/util'

module Lafcadio
	# The Collector searches for certain collections of domain objects in the 
	# database. These are in-SQL queries that are executed, so the time savings 
	# can be quite significant over returning all objects of a certain domain 
	# class and filtering them by hand in Ruby.
	#
	# The most commonly used method of the collector is in this format:
	#   Collector#get< domain class >s (searchTerm, fieldName = nil)
	# Which basically looks for instances of that domain class matching that 
	# search term. For example,
	#   Collector#getProducts (aProductCategory)
	# queries MySQL for all products that belong to that product category. If 
	# <tt>fieldName</tt> isn't given, it's inferred from the <tt>searchTerm</tt>. 
	# This works well for a search term that is a domain object, but for 
	# something more prosaic you'll probably need to set <tt>fieldName</tt> 
	# explicitly:
	#   Collector#getUsers ("Jones", "lastName")
	#
	# Don't call the Collector's method's directly: ObjectStore automatically 
	# dispatches methods to Collector if there's a match.
	class Collector
		def initialize(objectStore = Context.instance.getObjectStore)
			@objectStore = objectStore
		end

		def dispatch_get_method( objectTypeName, searchTerm, fieldName )
			if block_given? && searchTerm.nil?
				domain_class = DomainObject.getObjectTypeFromString( objectTypeName )
				inferrer = Query::Inferrer.new( domain_class ) { |obj| yield( obj ) }
				@objectStore.getSubset( inferrer.execute )
			elsif !block_given? && !searchTerm.nil?
				getFiltered(objectTypeName, searchTerm, fieldName)
			else
				raise( ArgumentError,
							 "Shouldn't send both a query block and a search term",
							 caller )
			end
		end

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
			@objectStore.getSubset condition
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

		def method_missing(methodId, searchTerm = nil, fieldName = nil)
			require 'lafcadio/util/English'
			methodName = methodId.id2name
			if methodName =~ /^get(.*)$/
				objectTypeName = English.singular($1)
				if block_given?
					dispatch_get_method( objectTypeName, searchTerm, fieldName ) { |obj|
						yield( obj )
					}
				else
					dispatch_get_method( objectTypeName, searchTerm, fieldName )
				end
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
			fieldName = mapped.objectType.bareName.decapitalize
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
end
