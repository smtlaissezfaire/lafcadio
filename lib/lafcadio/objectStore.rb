require 'dbi'
require 'lafcadio/depend'
require 'lafcadio/domain'
require 'lafcadio/query'
require 'lafcadio/util'

module Lafcadio
	class Committer #:nodoc:
		INSERT 	= 1
		UPDATE 	= 2
		DELETE  = 3

		attr_reader :commit_type, :db_object

		def initialize(db_object, dbBridge, cache)
			@db_object = db_object
			@dbBridge = dbBridge
			@cache = cache
			@objectStore = ObjectStore.get_object_store
			@commit_type = nil
		end
		
		def execute
			@db_object.verify if LafcadioConfig.new()['checkFields'] == 'onCommit'
			set_commit_type
			@db_object.last_commit_type = get_last_commit
			@db_object.pre_commit_trigger
			update_dependent_domain_objects if @db_object.delete
		end

		def get_last_commit
			if @db_object.delete
				DomainObject::COMMIT_DELETE
			elsif @db_object.pk_id
				DomainObject::COMMIT_EDIT
			else
				DomainObject::COMMIT_ADD
			end
		end
		
		def set_commit_type
			if @db_object.delete
				@commit_type = DELETE
			elsif @db_object.pk_id
				@commit_type = UPDATE
			else
				@commit_type = INSERT
			end
		end

		def update_dependent_domain_objects
			dependent_classes = @db_object.domain_class.dependent_classes
			dependent_classes.keys.each { |aClass|
				field = dependent_classes[aClass]
				collection = @objectStore.get_filtered( aClass.name, @db_object,
																							 field.name )
				collection.each { |dependentObject|
					if field.delete_cascade
						dependentObject.delete = true
					else
						dependentObject.send( field.name + '=', nil )
					end
					@objectStore.commit(dependentObject)
				}
			}
		end
	end

	class CouldntMatchDomainClassError < RuntimeError #:nodoc:
	end

	class DbBridge #:nodoc:
		@@last_pk_id_inserted = nil
		
		def self._load(aString)
			aString =~ /db_conn:/
			db_conn_str = $'
			begin
				db_conn = Marshal.load db_conn_str
			rescue TypeError
				db_conn = nil
			end
			DbConnection.set_db_connection db_conn
			new
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
		
		def collection_by_query(query)
			domain_class = query.domain_class
			execute_select( query.to_sql ).collect { |row_hash|
				domain_class.new( SqlValueConverter.new( domain_class, row_hash ) )
			}
		end
		
		def commit(db_object)
			sqlMaker = DomainObjectSqlMaker.new(db_object)
			sqlMaker.sql_statements.each { |sql, binds| execute_commit( sql, binds ) }
			if sqlMaker.sql_statements[0].first =~ /insert/
				sql = 'select last_insert_id()'
				result = execute_select( sql )
				@@last_pk_id_inserted = result[0]['last_insert_id()'].to_i
			end
		end
		
		def execute_commit( sql, binds ); @db_conn.do( sql, *binds ); end
		
		def execute_select(sql)
			maybe_log sql
			begin
				@db_conn.select_all( sql )
			rescue DBI::DatabaseError => e
				raise $!.to_s + ": #{ e.errstr }"
			end	
		end
		
		def group_query( query )
			execute_select( query.to_sql ).map { |row| query.result_row( row ) }
		end

		def last_pk_id_inserted; @@last_pk_id_inserted; end
		
		def maybe_log(sql)
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
		
		def transaction( action )
			tr = Transaction.new @db_conn
			tr.commit
			begin
				action.call tr
				tr.commit
			rescue RollbackError
				# rollback handled by Transaction
			rescue
				err_to_raise = $!
				tr.rollback false
				raise err_to_raise
			end
		end
		
		class Transaction
			def initialize( db_conn ); @db_conn = db_conn; end
			
			def commit; @db_conn.commit; end
				
			def rollback( raise_error = true )
				@db_conn.rollback
				raise RollbackError if raise_error
			end
		end
		
		class RollbackError < StandardError; end
	end

	class DbConnection < ContextualService::Service
		@@connectionClass = DBI
		@@db_name = nil
		@@dbh = nil

		def self.flush
			DbConnection.set_db_connection( nil )
			@@dbh = nil
		end

		def self.set_connection_class( aClass ); @@connectionClass = aClass; end

		def self.set_db_name( db_name ); @@db_name = db_name; end

		def self.set_dbh( dbh ); @@dbh = dbh; end
		
		def initialize
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
			@@dbh['AutoCommit'] = false
			@@dbh
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
	# linked to other domain objects with DomainObjectFields. In terms of +domain_class+
	# and 
	# +pk_id+, a DomainObjectProxy instance looks to the outside world like the 
	# domain object it's supposed to represent. It only retrieves its domain 
	# object from the database when member data is requested.
	#
	# In normal usage you will probably never manipulate a DomainObjectProxy
	# directly, but you may discover it by accident by calling
	# DomainObjectProxy#class (or DomainObject#class) instead of
	# DomainObjectProxy#domain_class (or DomainObjectProxy#domain_class).
	class DomainObjectProxy
		include DomainComparable

		attr_accessor :domain_class, :pk_id

		def initialize(domain_classOrDbObject, pk_id = nil)
			if pk_id
				@domain_class = domain_classOrDbObject
				@pk_id = pk_id
			elsif domain_classOrDbObject.class < DomainObject
				@db_object = domain_classOrDbObject
				@d_obj_retrieve_time = Time.now
				@domain_class = @db_object.class
				@pk_id = @db_object.pk_id
			else
				raise ArgumentError
			end
			@db_object = nil
		end

		def get_db_object
			object_store = ObjectStore.get_object_store
			if @db_object.nil? || needs_refresh?
				@db_object = object_store.get( @domain_class, @pk_id )
				@d_obj_retrieve_time = Time.now
			end
			@db_object
		end

		def hash
			get_db_object.hash
		end

		def method_missing(methodId, *args)
			get_db_object.send(methodId.id2name, *args)
		end

		def needs_refresh?
			object_store = ObjectStore.get_object_store
			last_commit_time = object_store.last_commit_time( @domain_class, @pk_id )
			!last_commit_time.nil? && last_commit_time > @d_obj_retrieve_time
		end
		
		def to_s
			get_db_object.to_s
		end
	end

	class DomainObjectSqlMaker #:nodoc:
		attr_reader :bind_values

		def initialize(obj); @obj = obj; end

		def delete_sql( domain_class )
			"delete from #{ domain_class.table_name} " +
					"where #{ domain_class.sql_primary_key_name }=#{ @obj.pk_id }"
		end

		def get_name_value_pairs( domain_class )
			nameValues = []
			domain_class.class_fields.each { |field|
				unless field.instance_of?( PrimaryKeyField )
					value = @obj.send(field.name)
					unless field.db_will_automatically_write?
						nameValues << field.db_field_name
						nameValues <<(field.value_for_sql(value))
					end
					if field.bind_write?
						@bind_values << value
					end
				end
			}
			QueueHash.new( *nameValues )
		end

		def insert_sql( domain_class )
			fields = domain_class.class_fields
			nameValuePairs = get_name_value_pairs( domain_class )
			if domain_class.is_child_domain_class?
				nameValuePairs[domain_class.sql_primary_key_name] = 'LAST_INSERT_ID()'
			end
			fieldNameStr = nameValuePairs.keys.join ", "
			fieldValueStr = nameValuePairs.values.join ", "
			"insert into #{ domain_class.table_name}(#{fieldNameStr}) " +
					"values(#{fieldValueStr})"
		end

		def sql_statements
			statements = []
			@obj.class.self_and_concrete_superclasses.each { |domain_class|
				statements << statement_bind_value_pair( domain_class )
 			}
			statements.reverse
		end

		def statement_bind_value_pair( domain_class )
			@bind_values = []
			if @obj.pk_id == nil
				statement = insert_sql( domain_class )
			else
				if @obj.delete
					statement = delete_sql( domain_class )
				else
					statement = update_sql( domain_class)
				end
			end
			[statement, @bind_values]
		end

		def update_sql( domain_class )
			nameValueStrings = []
			nameValuePairs = get_name_value_pairs( domain_class )
			nameValuePairs.each { |key, value|
				nameValueStrings << "#{key}=#{ value }"
			}
			allNameValues = nameValueStrings.join ', '
			"update #{ domain_class.table_name} set #{allNameValues} " +
					"where #{ domain_class.sql_primary_key_name}=#{@obj.pk_id}"
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
	# [ObjectStore#get< domain class > (pk_id)]
	#   Retrieves one domain object by pk_id. For example,
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
	# DomainObject#pre_commit_trigger and DomainObject#post_commit_trigger for more.
	class ObjectStore < ContextualService::Service
		def self.mock?; get_object_store.mock?; end
		
		def self.set_db_name(dbName) #:nodoc:
			DbConnection.set_db_name dbName
		end
		
		def initialize( dbBridge = nil ) #:nodoc:
			@dbBridge = dbBridge == nil ? DbBridge.new : dbBridge
			@cache = ObjectStore::Cache.new( @dbBridge )
		end

		# Commits a domain object to the database. You can also simply call
		#   myDomainObject.commit
		def commit(db_object)
			@cache.commit( db_object )
			db_object
		end
		
		# Flushes one domain object from its cache.
		def flush(db_object)
			@cache.flush db_object
		end

		# Returns the domain object corresponding to the domain class and pk_id.
		def get( domain_class, pk_id )
			query = Query.new domain_class, pk_id
			@cache.get_by_query( query )[0] ||
			    ( raise( DomainObjectNotFoundError,
					         "Can't find #{domain_class} #{pk_id}", caller ) )
		end

		# Returns all domain objects for the given domain class.
		def get_all(domain_class); @cache.get_by_query( Query.new( domain_class ) ); end

		# Returns the DbBridge; this is useful in case you need to use raw SQL for a
		# specific query.
		def get_db_bridge; @dbBridge; end
		
		def get_field_name( domain_object )
			domain_object.domain_class.basename.camel_case_to_underscore
		end

		def get_filtered(domain_class_name, searchTerm, fieldName = nil) #:nodoc:
			domain_class = Class.by_name domain_class_name
			unless fieldName
				fieldName = domain_class.link_field( searchTerm.domain_class ).name
			end
			get_subset( Query::Equals.new( fieldName, searchTerm, domain_class ) )
		end

		def get_map_match( domain_class, mapped ) #:nodoc:
			Query::Equals.new( get_field_name( mapped ), mapped, domain_class )
		end

		def get_map_object( domain_class, map1, map2 ) #:nodoc:
			unless map1 && map2
				raise ArgumentError,
						"ObjectStore#get_map_object needs two non-nil keys", caller
			end
			mapMatch1 = get_map_match domain_class, map1
			mapMatch2 = get_map_match domain_class, map2
			condition = Query::CompoundCondition.new mapMatch1, mapMatch2
			get_subset(condition)[0]
		end

		def get_mapped(searchTerm, resultTypeName) #:nodoc:
			resultType = Module.by_name resultTypeName
			firstTypeName = searchTerm.class.basename
			secondTypeName = resultType.basename
			mapTypeName = firstTypeName + secondTypeName
			get_filtered( mapTypeName, searchTerm ).collect { |mapObj|
				mapObj.send( resultType.name.decapitalize )
			}
		end
		
		# Retrieves the maximum value across all instances of one domain class.
		#   ObjectStore#get_max( Client )
		# returns the highest +pk_id+ in the +clients+ table.
		#   ObjectStore#get_max( Invoice, "rate" )
		# will return the highest rate for all invoices.
		def get_max( domain_class, field_name = 'pk_id' )
			qry = Query::Max.new( domain_class, field_name )
			@dbBridge.group_query( qry ).only[:max]
		end

		# Retrieves a collection of domain objects by +pk_id+.
		#   ObjectStore#get_objects( Clients, [ 1, 2, 3 ] )
		def get_objects( domain_class, pk_ids )
			if pk_ids.is_a?( Array ) && pk_ids.all? { |elt| elt.is_a?( Integer ) }
				get_subset Query::In.new( 'pk_id', pk_ids, domain_class )
			else
				raise(
					ArgumentError, 
					"ObjectStore#get_objects( domain_class, pk_ids ): pk_ids needs to " +
							"be an array of integers",
					caller
				)
			end
		end

		def get_subset(conditionOrQuery) #:nodoc:
			if conditionOrQuery.class <= Query::Condition
				condition = conditionOrQuery
				query = Query.new condition.domain_class, condition
			else
				query = conditionOrQuery
			end
			@cache.get_by_query( query )
		end
		
		def last_commit_time( domain_class, pk_id ) #:nodoc:
			@cache.last_commit_time( domain_class, pk_id )
		end

		def method_missing(methodId, *args) #:nodoc:
			proc = block_given? ? ( proc { |obj| yield( obj ) } ) : nil
			dispatch = MethodDispatch.new( methodId, proc, *args )
			self.send( dispatch.symbol, *dispatch.args )
		end
		
		def mock? #:nodoc:
			false
		end
		
		def query( query ); @dbBridge.group_query( query ); end

		def respond_to?( symbol, include_private = false )
			begin
				dispatch = MethodDispatch.new( symbol )
			rescue NoMethodError
				super
			end
		end
		
		def transaction( &action ); @dbBridge.transaction( action ); end
		
		class Cache #:nodoc:
			def initialize( dbBridge )
				@dbBridge = dbBridge
				@objects = {}
				@collections_by_query = {}
				@commit_times = {}
			end

			def commit( db_object )
				committer = Committer.new db_object, @dbBridge, self
				committer.execute
				@dbBridge.commit db_object
				db_object.pk_id = @dbBridge.last_pk_id_inserted unless db_object.pk_id
				update_after_commit committer
				db_object.post_commit_trigger
			end

			# Flushes a domain object.
			def flush(db_object)
				hash_by_domain_class( db_object.domain_class ).delete db_object.pk_id
				flush_collection_cache( db_object.domain_class )
			end
			
			def flush_collection_cache( domain_class )
				@collections_by_query.keys.each { |query|
					if query.domain_class == domain_class
						@collections_by_query.delete( query )
					end
				}
			end

			# Returns a cached domain object, or nil if none is found.
			def get( domain_class, pk_id )
				if ( dobj = hash_by_domain_class( domain_class )[pk_id] )
					dobj.clone
				else
					nil
				end
			end

			# Returns an array of all domain objects of a given type.
			def get_all( domain_class )
				hash_by_domain_class( domain_class ).values.collect { |d_obj|
					d_obj.clone
				}
			end

			def get_by_query( query )
				unless @collections_by_query[query]
					superset_query, pk_ids =
						@collections_by_query.find { |other_query, pk_ids|
							query.implies?( other_query )
						}
					if pk_ids
						@collections_by_query[query] = ( pk_ids.collect { |pk_id|
							get( query.domain_class, pk_id )
						} ).select { |dobj| query.object_meets( dobj ) }.collect { |dobj|
							dobj.pk_id
						}
					elsif @collections_by_query.values
						newObjects = @dbBridge.collection_by_query(query)
						newObjects.each { |dbObj| save dbObj }
						@collections_by_query[query] = newObjects.collect { |dobj|
							dobj.pk_id
						}
					end
				end
				collection = []
				@collections_by_query[query].each { |pk_id|
					dobj = get( query.domain_class, pk_id )
					collection << dobj if dobj
				}
				collection
			end

			def hash_by_domain_class( domain_class )
				unless @objects[domain_class]
					@objects[domain_class] = {}
				end
				@objects[domain_class]
			end

			def last_commit_time( domain_class, pk_id )
				by_domain_class = @commit_times[domain_class]
				by_domain_class ? by_domain_class[pk_id] : nil
			end
			
			def set_commit_time( d_obj )
				by_domain_class = @commit_times[d_obj.domain_class]
				if by_domain_class.nil?
					by_domain_class = {}
					@commit_times[d_obj.domain_class] = by_domain_class
				end
				by_domain_class[d_obj.pk_id] = Time.now
			end

			# Saves a domain object.
			def save(db_object)
				hash = hash_by_domain_class( db_object.domain_class )
				hash[db_object.pk_id] = db_object
				flush_collection_cache( db_object.domain_class )
			end
			
			def update_after_commit( committer ) #:nodoc:
				if committer.commit_type == Committer::UPDATE ||
					committer.commit_type == Committer::INSERT
					save( committer.db_object )
				elsif committer.commit_type == Committer::DELETE
					flush( committer.db_object )
				end
				set_commit_time( committer.db_object )
			end
		end

		class MethodDispatch #:nodoc:
			attr_reader :symbol, :args
		
			def initialize( orig_method, *other_args )
				@orig_method = orig_method
				@orig_args = other_args
				if @orig_args.size > 0
					@maybe_proc = @orig_args.shift
				end
				@methodName = orig_method.id2name
				if @methodName =~ /^get(.*)$/
					dispatch_get_method
				else
					raise_no_method_error
				end
			end
			
			def dispatch_get_plural
				if @orig_args.size == 0 && @maybe_proc.nil?
					@symbol = :get_all
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
				@symbol = :get_subset
				@args = [ inferrer.execute ]
			end

			def dispatch_get_plural_by_query_block_or_search_term( searchTerm,
					                                                   fieldName )
				if !@maybe_proc.nil? && searchTerm.nil?
					dispatch_get_plural_by_query_block
				elsif @maybe_proc.nil? && ( !( searchTerm.nil? && fieldName.nil? ) )
					@symbol = :get_filtered
					@args = [ @domain_class.name, searchTerm, fieldName ]
				else
					raise( ArgumentError,
					 	     "Shouldn't send both a query block and a search term",
					       caller )
				end
			end
			
			def dispatch_get_method
				unless ( dispatch_get_singular )
					domain_class_name = camel_case_method_name_after_get.singular
					begin
						@domain_class = Module.by_name domain_class_name
						dispatch_get_plural
					rescue NameError
						raise_no_method_error
					end
				end
			end
			
			def dispatch_get_singular
				begin
					domain_class = Module.by_name camel_case_method_name_after_get
					if @orig_args[0].class <= Integer
						@symbol = :get
						@args = [ domain_class, @orig_args[0] ]
					elsif @orig_args[0].class <= DomainObject
						@symbol = :get_map_object
						@args = [ domain_class, @orig_args[0], @orig_args[1] ]
					end
					true
				rescue NameError
					false
				end
			end
			
			def camel_case_method_name_after_get
				@orig_method.id2name =~ /^get(.*)$/
				$1.underscore_to_camel_case
			end
			
			def raise_no_method_error
				raise( NoMethodError, "undefined method '#{ @methodName }'", caller )
			end
		end
	end

	class SqlValueConverter #:nodoc:
		attr_reader :domain_class, :row_hash

		def initialize( domain_class, row_hash )
			@domain_class = domain_class
			@row_hash = row_hash
		end

		def []( key )
			if ( field = @domain_class.field key )
				val = field.value_from_sql( @row_hash[ field.db_field_name ] )
				if field.instance_of?( PrimaryKeyField ) && val.nil?
					raise FieldMatchError, error_msg, caller
				else
					val
				end
			else
				nil
			end
		end

		def error_msg
			"The field \"" + @domain_class.sql_primary_key_name +
					"\" can\'t be found in the table \"" + 
					@domain_class.table_name + "\"."
		end
	end
end