require 'lafcadio'

module Lafcadio
	# The ObjectStore represents the database in a Lafcadio application.
	#
	# = Configuring the ObjectStore
	# The ObjectStore depends on a few values being set correctly in the
	# LafcadioConfig file:
	# [dbuser]     The database username.
	# [dbpassword] The database password.
	# [dbname]     The database name.
	# [dbhost]     The database host.
	#
	# = Instantiating ObjectStore
	# The ObjectStore is a ContextualService, meaning you can't get an instance by
	# calling ObjectStore.new. Instead, you should call
	# ObjectStore.getObjectStore. (Using a ContextualService makes it easier to
	# make out the ObjectStore for unit tests: See ContextualService for more.)
	#
	# = Dynamic method calls
	# ObjectStore uses reflection to provide a lot of convenience methods for
	# querying domain objects in a number of ways.
	# [ObjectStore#get< domain class > (pkId)]
	#   Retrieves one domain object by pkId. For example,
	#     ObjectStore#getUser( 100 )
	#   will return User 100.
	# [ObjectStore#get< domain class >s (searchTerm, fieldName = nil)]
	#   Returns a collection of all instances of that domain class matching that
	#   search term. For example,
	#     ObjectStore#getProducts( aProductCategory )
	#   queries MySQL for all products that belong to that product category. You
	#   can omit +fieldName+ if +searchTerm+ is a non-nil domain object, and the
	#   field connecting the first domain class to the second is named after the
	#   domain class. (For example, the above line assumes that Product has a
	#   field named "productCategory".) Otherwise, it's best to include
	#   +fieldName+:
	#     ObjectStore#getUsers( "Jones", "lastName" )
	#
	# = Querying
	# ObjectStore can also be used to generate complex, ad-hoc queries which
	# emulate much of the functionality you'd get from writing the SQL yourself.
	# Furthermore, these queries can be run against in-memory data stores, which
	# is particularly useful for tests.
	#   date = Date.new( 2003, 1, 1 )
	#   ObjectStore#getInvoices { |invoice|
	#     Query.And( invoice.date.gte( date ), invoice.rate.equals( 10 ),
	#                invoice.hours.equals( 10 ) )
	#   }
	# is the same as
	#   select * from invoices
	#   where (date >= '2003-01-01' and rate = 10 and hours = 10)
	# See lafcadio/query.rb for more.
	#
	# = SQL Logging
	# Lafcadio uses log4r to log all of its SQL statements. The simplest way to
	# turn on logging is to set the following values in the LafcadioConfig file:
	# [logSql]     Should be set to "y" to turn on logging.
	# [logdir]     The directory where log files should be written. Required if
	#              +logSql+ is "y"
	# [sqlLogFile] The name of the file (not including its directory) where SQL
	#              should be logged. Default is "sql".
	#
	# = Triggers
	# Domain classes can be set to fire triggers either before or after commits.
	# Since these triggers are executed in Ruby, they're easy to test. See
	# DomainObject#preCommitTrigger and DomainObject#postCommitTrigger for more.
	class ObjectStore < ContextualService
		def ObjectStore.setDbName(dbName) #:nodoc:
			DbBridge.setDbName dbName
		end
		
		def initialize(context, dbBridge = nil) #:nodoc:
			super context
			@dbBridge = dbBridge == nil ? DbBridge.new : dbBridge
			@cache = ObjectStore::Cache.new( @dbBridge )
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

		# Returns the domain object corresponding to the domain class and pkId.
		def get(objectType, pkId)
			query = Query.new objectType, pkId
			@cache.getByQuery( query )[0] ||
			    ( raise( DomainObjectNotFoundError,
					         "Can't find #{objectType} #{pkId}", caller ) )
		end

		# Returns all domain objects for the given domain class.
		def getAll(objectType)
			query = Query.new( objectType )
			@cache.getByQuery( query )
		end

		# Returns the DbBridge; this is useful in case you need to use raw SQL for a
		# specific query.
		def getDbBridge; @dbBridge; end

		def getFiltered(objectTypeName, searchTerm, fieldName = nil) #:nodoc:
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

		def getMapMatch(objectType, mapped) #:nodoc:
			fieldName = mapped.objectType.bareName.decapitalize
			Query::Equals.new(fieldName, mapped, objectType)
		end

		def getMapObject(objectType, map1, map2) #:nodoc:
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

		def getMapped(searchTerm, resultTypeName) #:nodoc:
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
		
		# Retrieves the maximum value across all instances of one domain class.
		#   ObjectStore#getMax( Client )
		# returns the highest +pkId+ in the +clients+ table.
		#   ObjectStore#getMax( Invoice, "rate" )
		# will return the highest rate for all invoices.
		def getMax( domain_class, field_name = 'pkId' )
			query = Query::Max.new( domain_class, field_name )
			@dbBridge.group_query( query ).only
		end

		# Retrieves a collection of domain objects by +pkId+.
		#   ObjectStore#getObjects( Clients, [ 1, 2, 3 ] )
		def getObjects(objectType, pkIds)
			require 'lafcadio/query/In'
			condition = Query::In.new('pkId', pkIds, objectType)
			getSubset condition
		end

		def getSubset(conditionOrQuery) #:nodoc:
			if conditionOrQuery.class <= Query::Condition
				condition = conditionOrQuery
				query = Query.new condition.objectType, condition
			else
				query = conditionOrQuery
			end
			@cache.getByQuery( query )
		end
		
		def last_commit_time( domain_class, pkId ) #:nodoc:
			@cache.last_commit_time( domain_class, pkId )
		end

		def method_missing(methodId, *args) #:nodoc:
			proc = block_given? ? ( proc { |obj| yield( obj ) } ) : nil
			dispatch = MethodDispatch.new( methodId, proc, *args )
			self.send( dispatch.symbol, *dispatch.args )
		end
		
		# Caches one domain object.
		def set(dbObject)
			@cache.save dbObject
		end
		
		def updateCacheAfterCommit( committer ) #:nodoc:
			if committer.commitType == Committer::UPDATE ||
				committer.commitType == Committer::INSERT
				set( committer.dbObject )
			elsif committer.commitType == Committer::DELETE
				@cache.flush( committer.dbObject )
			end
			@cache.set_commit_time( committer.dbObject )
		end
	end
end
