require 'rubygems'
require 'dbi'
require_gem 'log4r'
require 'lafcadio/domain'
require 'lafcadio/query'
require 'lafcadio/util'

module Lafcadio
	class Committer #:nodoc:
		INSERT 	= 1
		UPDATE 	= 2
		DELETE  = 3

		attr_reader :commitType, :dbObject

		def initialize(dbObject, dbBridge)
			@dbObject = dbObject
			@dbBridge = dbBridge
			@objectStore = Context.instance.get_object_store
			@commitType = nil
		end
		
		def execute
			@dbObject.verify if LafcadioConfig.new()['checkFields'] == 'onCommit'
			setCommitType
			@dbObject.lastCommit = getLastCommit
			@dbObject.preCommitTrigger
			update_dependent_domain_objects if @dbObject.delete
			@dbBridge.commit @dbObject
			unless @dbObject.pkId
				@dbObject.pkId = @dbBridge.lastPkIdInserted
			end
			@dbObject.postCommitTrigger
		end

		def getLastCommit
			if @dbObject.delete
				DomainObject::COMMIT_DELETE
			elsif @dbObject.pkId
				DomainObject::COMMIT_EDIT
			else
				DomainObject::COMMIT_ADD
			end
		end
		
		def setCommitType
			if @dbObject.delete
				@commitType = DELETE
			elsif @dbObject.pkId
				@commitType = UPDATE
			else
				@commitType = INSERT
			end
		end

		def update_dependent_domain_objects
			dependentClasses = @dbObject.objectType.dependentClasses
			dependentClasses.keys.each { |aClass|
				field = dependentClasses[aClass]
				collection = @objectStore.getFiltered( aClass.name, @dbObject,
																							 field.name )
				collection.each { |dependentObject|
					if field.deleteCascade
						dependentObject.delete = true
					else
						dependentObject.send( field.name + '=', nil )
					end
					@objectStore.commit(dependentObject)
				}
			}
		end
	end

	class CouldntMatchObjectTypeError < RuntimeError #:nodoc:
	end

	class DbBridge #:nodoc:
		@@dbh = nil
		@@lastPkIdInserted = nil
		
		def self._load(aString)
			aString =~ /dbh:/
			dbString = $'
			begin
				dbh = Marshal.load(dbString)
			rescue TypeError
				dbh = nil
			end
			new dbh
		end
		
		def initialize
			@db_conn = DbConnection.get_db_connection
			ObjectSpace.define_finalizer( self, proc { |id|
				DbConnection.get_db_connection.disconnect
			} )
		end

		def _dump(aDepth)
			dbDump = @dbh.respond_to?( '_dump' ) ? @dbh._dump : @dbh.class.to_s
			"dbh:#{dbDump}"
		end
		
		def commit(dbObject)
			sqlMaker = DomainObjectSqlMaker.new(dbObject)
			sqlMaker.sqlStatements.each { |sql, binds| executeCommit( sql, binds ) }
			if sqlMaker.sqlStatements[0].first =~ /insert/
				sql = 'select last_insert_id()'
				result = executeSelect( sql )
				@@lastPkIdInserted = result[0]['last_insert_id()'].to_i
			end
		end
		
		def executeCommit( sql, binds ); @db_conn.do( sql, *binds ); end
		
		def executeSelect(sql)
			maybeLog sql
			begin
				@db_conn.select_all( sql )
			rescue DBI::DatabaseError => e
				raise $!.to_s + ": #{ e.errstr }"
			end	
		end
		
		def getCollectionByQuery(query)
			objectType = query.objectType
			executeSelect( query.toSql ).collect { |row_hash|
				objectType.new( SqlValueConverter.new( objectType, row_hash ) )
			}
		end
		
		def group_query( query )
			executeSelect( query.toSql )[0].collect { |val|
				if query.field_name != query.objectType.sqlPrimaryKeyName
					a_field = query.objectType.getField( query.field_name )
					a_field.valueFromSQL( val )
				else
					val.to_i
				end
			}
		end

		def lastPkIdInserted; @@lastPkIdInserted; end
		
		def maybeLog(sql)
			config = LafcadioConfig.new
			if config['logSql'] == 'y'
				sqllog = Log4r::Logger['sql'] || Log4r::Logger.new( 'sql' )
				filename = File.join( config['logdir'], config['sqlLogFile'] || 'sql' )
				outputter = Log4r::FileOutputter.new( 'outputter',
																							{ :filename => filename } )
				sqllog.outputters = outputter
				sqllog.info sql
			end
		end
	end

	class DbConnection < ContextualService
		@@connectionClass = DBI
		@@db_name = nil
		@@dbh = nil

		def self.flush
			Context.instance.setDbConnection( nil )
			@@dbh = nil
		end

		def self.set_connection_class( aClass ); @@connectionClass = aClass; end

		def self.set_db_name( db_name ); @@db_name = db_name; end

		def self.set_dbh( dbh ); @@dbh = dbh; end
		
		def initialize( pass_key )
			super
			@@dbh = load_new_dbh if @@dbh.nil?
			@dbh = @@dbh
		end
	
		def disconnect; @dbh.disconnect if @dbh; end
		
		def load_new_dbh
			config = LafcadioConfig.new
			dbName = @@db_name || config['dbname']
			dbAndHost = nil
			if dbName && config['dbhost']
				dbAndHost = "dbi:Mysql:#{ dbName }:#{ config['dbhost'] }"
			else
				dbAndHost = "dbi:#{config['dbconn']}"
			end
			@@dbh = @@connectionClass.connect( dbAndHost, config['dbuser'],
																				 config['dbpassword'] )
		end
		
		def method_missing( symbol, *args )
			@dbh.send( symbol, *args )
		end
	end

	class DomainObjectInitError < RuntimeError #:nodoc:
		attr_reader :messages

		def initialize(messages)
			@messages = messages
		end
	end

	class DomainObjectNotFoundError < RuntimeError #:nodoc:
	end

	# The DomainObjectProxy is used when retrieving domain objects that are 
	# linked to other domain objects with LinkFields. In terms of +objectType+ and 
	# +pkId+, a DomainObjectProxy instance looks to the outside world like the 
	# domain object it's supposed to represent. It only retrieves its domain 
	# object from the database when member data is requested.
	#
	# In normal usage you will probably never manipulate a DomainObjectProxy
	# directly, but you may discover it by accident by calling
	# DomainObjectProxy#class (or DomainObject#class) instead of
	# DomainObjectProxy#objectType (or DomainObjectProxy#objectType).
	class DomainObjectProxy
		include DomainComparable

		attr_accessor :objectType, :pkId

		def initialize(objectTypeOrDbObject, pkId = nil)
			if pkId
				@objectType = objectTypeOrDbObject
				@pkId = pkId
			elsif objectTypeOrDbObject.class < DomainObject
				@dbObject = objectTypeOrDbObject
				@d_obj_retrieve_time = Time.now
				@objectType = @dbObject.class
				@pkId = @dbObject.pkId
			else
				raise ArgumentError
			end
			@dbObject = nil
		end

		def getDbObject
			object_store = ObjectStore.get_object_store
			if @dbObject.nil? || needs_refresh?
				@dbObject = object_store.get(@objectType, @pkId)
								@d_obj_retrieve_time = Time.now

			end
			@dbObject
		end

		def hash
			getDbObject.hash
		end

		def method_missing(methodId, *args)
			getDbObject.send(methodId.id2name, *args)
		end

		def needs_refresh?
			object_store = ObjectStore.get_object_store
			last_commit_time = object_store.last_commit_time( @objectType, @pkId )
			!last_commit_time.nil? && last_commit_time > @d_obj_retrieve_time
		end
		
		def to_s
			getDbObject.to_s
		end
	end

	class DomainObjectSqlMaker #:nodoc:
		attr_reader :bindValues

		def initialize(obj); @obj = obj; end

		def deleteSql(objectType)
			"delete from #{ objectType.tableName} " +
					"where #{ objectType.sqlPrimaryKeyName }=#{ @obj.pkId }"
		end

		def getNameValuePairs(objectType)
			nameValues = []
			objectType.classFields.each { |field|
				value = @obj.send(field.name)
				unless field.dbWillAutomaticallyWrite
					nameValues << field.nameForSQL
					nameValues <<(field.valueForSQL(value))
				end
				if field.bind_write?
					@bindValues << value
				end
			}
			QueueHash.new( *nameValues )
		end

		def insertSQL(objectType)
			fields = objectType.classFields
			nameValuePairs = getNameValuePairs(objectType)
			if objectType.isBasedOn?
				nameValuePairs[objectType.sqlPrimaryKeyName] = 'LAST_INSERT_ID()'
			end
			fieldNameStr = nameValuePairs.keys.join ", "
			fieldValueStr = nameValuePairs.values.join ", "
			"insert into #{ objectType.tableName}(#{fieldNameStr}) " +
					"values(#{fieldValueStr})"
		end

		def sqlStatements
			statements = []
			if @obj.errorMessages.size > 0
				raise DomainObjectInitError, @obj.errorMessages, caller
			end
			@obj.class.selfAndConcreteSuperclasses.each { |objectType|
				statements << statement_bind_value_pair( objectType )
 			}
			statements.reverse
		end

		def statement_bind_value_pair( objectType )
			@bindValues = []
			if @obj.pkId == nil
				statement = insertSQL(objectType)
			else
				if @obj.delete
					statement = deleteSql(objectType)
				else
					statement = updateSQL(objectType)
				end
			end
			[statement, @bindValues]
		end

		def updateSQL(objectType)
			nameValueStrings = []
			nameValuePairs = getNameValuePairs(objectType)
			nameValuePairs.each { |key, value|
				nameValueStrings << "#{key}=#{ value }"
			}
			allNameValues = nameValueStrings.join ', '
			"update #{ objectType.tableName} set #{allNameValues} " +
					"where #{ objectType.sqlPrimaryKeyName}=#{@obj.pkId}"
		end
	end

	class FieldMatchError < StandardError; end

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
	# ObjectStore.get_object_store. (Using a ContextualService makes it easier to
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
			DbConnection.set_db_name dbName
		end
		
		def initialize(context, dbBridge = nil) #:nodoc:
			super context
			@dbBridge = dbBridge == nil ? DbBridge.new : dbBridge
			@cache = ObjectStore::Cache.new( @dbBridge )
		end

		# Commits a domain object to the database. You can also simply call
		#   myDomainObject.commit
		def commit(dbObject)
			@cache.commit( dbObject )
			dbObject
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
		def getAll(objectType); @cache.getByQuery( Query.new( objectType ) ); end

		# Returns the DbBridge; this is useful in case you need to use raw SQL for a
		# specific query.
		def getDbBridge; @dbBridge; end
		
		def get_field_name( domain_object )
			domain_object.objectType.bareName.decapitalize
		end

		def getFiltered(objectTypeName, searchTerm, fieldName = nil) #:nodoc:
			objectType = DomainObject.getObjectTypeFromString objectTypeName
			fieldName = get_field_name( searchTerm ) unless fieldName
			if searchTerm.class <= DomainObject
				cond_class = Query::Link
			else
				cond_class = Query::Equals
			end
			getSubset( cond_class.new( fieldName, searchTerm, objectType ) )
		end

		def getMapMatch(objectType, mapped) #:nodoc:
			Query::Equals.new( get_field_name( mapped ), mapped, objectType )
		end

		def getMapObject(objectType, map1, map2) #:nodoc:
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
			firstTypeName = searchTerm.class.bareName
			secondTypeName = resultType.bareName
			mapTypeName = firstTypeName + secondTypeName
			getFiltered( mapTypeName, searchTerm ).collect { |mapObj|
				mapObj.send( resultType.name.decapitalize )
			}
		end
		
		# Retrieves the maximum value across all instances of one domain class.
		#   ObjectStore#getMax( Client )
		# returns the highest +pkId+ in the +clients+ table.
		#   ObjectStore#getMax( Invoice, "rate" )
		# will return the highest rate for all invoices.
		def getMax( domain_class, field_name = nil )
			@dbBridge.group_query( Query::Max.new( domain_class, field_name ) ).only
		end

		# Retrieves a collection of domain objects by +pkId+.
		#   ObjectStore#getObjects( Clients, [ 1, 2, 3 ] )
		def getObjects(objectType, pkIds)
			getSubset Query::In.new('pkId', pkIds, objectType)
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

		class Cache #:nodoc:
			def initialize( dbBridge )
				@dbBridge = dbBridge
				@objects = {}
				@collections_by_query = {}
				@commit_times = {}
			end

			def commit( dbObject )
				committer = Committer.new dbObject, @dbBridge
				committer.execute
				update_after_commit( committer )
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

			# Returns a cached domain object, or nil if none is found.
			def get(objectType, pkId)
				hashByObjectType(objectType)[pkId].clone
			end

			# Returns an array of all domain objects of a given type.
			def getAll(objectType)
				hashByObjectType(objectType).values.collect { |d_obj| d_obj.clone }
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

			def hashByObjectType(objectType)
				unless @objects[objectType]
					@objects[objectType] = {}
				end
				@objects[objectType]
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

			# Saves a domain object.
			def save(dbObject)
				hashByObjectType(dbObject.objectType)[dbObject.pkId] = dbObject
				flush_collection_cache( dbObject.objectType )
			end
			
			def update_after_commit( committer ) #:nodoc:
				if committer.commitType == Committer::UPDATE ||
					committer.commitType == Committer::INSERT
					save( committer.dbObject )
				elsif committer.commitType == Committer::DELETE
					flush( committer.dbObject )
				end
				set_commit_time( committer.dbObject )
			end
		end

		class MethodDispatch #:nodoc:
			attr_reader :symbol, :args
		
			def initialize( orig_method, maybe_proc, *orig_args )
				@orig_method = orig_method
				@maybe_proc = maybe_proc
				@orig_args = orig_args
				@methodName = orig_method.id2name
				if @methodName =~ /^get(.*)$/
					dispatch_get_method
				else
					raise_no_method_error
				end
			end
			
			def dispatch_get_plural
				if @orig_args.size == 0 && @maybe_proc.nil?
					@symbol = :getAll
					@args = [ @domain_class ]
				else
					searchTerm = @orig_args[0]
					fieldName = @orig_args[1]
					if searchTerm.nil? && @maybe_proc.nil? && fieldName.nil?
						msg = "ObjectStore\##{ @orig_method } needs a field name as its " +
						      "second argument if its first argument is nil"
						raise( ArgumentError, msg, caller )
					end
					dispatch_get_plural_by_query_block_or_search_term( searchTerm,
					                                                   fieldName )
				end
			end
			
			def dispatch_get_plural_by_query_block
				inferrer = Query::Inferrer.new( @domain_class ) { |obj|
					@maybe_proc.call( obj )
				}
				@symbol = :getSubset
				@args = [ inferrer.execute ]
			end

			def dispatch_get_plural_by_query_block_or_search_term( searchTerm,
					                                                   fieldName )
				if !@maybe_proc.nil? && searchTerm.nil?
					dispatch_get_plural_by_query_block
				elsif @maybe_proc.nil? && ( !( searchTerm.nil? && fieldName.nil? ) )
					@symbol = :getFiltered
					@args = [ @domain_class.name, searchTerm, fieldName ]
				else
					raise( ArgumentError,
					 	     "Shouldn't send both a query block and a search term",
					       caller )
				end
			end
			
			def dispatch_get_method
				begin
					dispatch_get_singular
				rescue CouldntMatchObjectTypeError
					objectTypeName = English.singular( method_name_after_get )
					begin
						@domain_class = DomainObject.
						                getObjectTypeFromString( objectTypeName )
						dispatch_get_plural
					rescue CouldntMatchObjectTypeError
						raise_no_method_error
					end
				end
			end
			
			def dispatch_get_singular
				objectType = DomainObject.
				             getObjectTypeFromString( method_name_after_get )
				if @orig_args[0].class <= Integer
					@symbol = :get
					@args = [ objectType, @orig_args[0] ]
				elsif @orig_args[0].class <= DomainObject
					@symbol = :getMapObject
					@args = [ objectType, @orig_args[0], @orig_args[1] ]
				end
			end
			
			def method_name_after_get
				@orig_method.id2name =~ /^get(.*)$/
				$1
			end
			
			def raise_no_method_error
				raise( NoMethodError, "undefined method '#{ @methodName }'", caller )
			end
		end
	end

	class SqlValueConverter #:nodoc:
		attr_reader :objectType, :rowHash

		def initialize(objectType, rowHash)
			@objectType = objectType
			@rowHash = rowHash
		end

		def []( key )
			if key == 'pkId'
				if ( field_val = @rowHash[@objectType.sqlPrimaryKeyName] ).nil?
					raise FieldMatchError, error_msg, caller
				else
					field_val.to_i
				end
			else
				begin
					field = @objectType.getField( key )
					field.valueFromSQL( @rowHash[ field.dbFieldName ] )
				rescue MissingError
					nil
				end
			end
		end

		def error_msg
			"The field \"" + @objectType.sqlPrimaryKeyName +
					"\" can\'t be found in the table \"" + 
					@objectType.tableName + "\"."
		end
	end
end