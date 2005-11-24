require 'dbi'
require 'lafcadio/depend'
require 'lafcadio/domain'
require 'lafcadio/query'
require 'lafcadio/util'

module Lafcadio
	class DomainObjectInitError < RuntimeError #:nodoc:
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

		def initialize( *args )
			if args.size == 2
				@domain_class = args.first
				@pk_id = args.last
			elsif args.first.is_a?( DomainObject )
				@d_obj_retrieve_time = Time.now
				@domain_class = args.first.class
				@pk_id = args.first.pk_id
			else
				raise ArgumentError
			end
		end

		def db_object
			if @db_object.nil? || needs_refresh?
				@db_object = ObjectStore.get_object_store.get( @domain_class, @pk_id )
				@d_obj_retrieve_time = Time.now
			end
			@db_object
		end

		def hash
			db_object.hash
		end

		def method_missing( methodId, *args )
			db_object.send( methodId, *args )
		end

		def needs_refresh?
			object_store = ObjectStore.get_object_store
			last_commit_time = object_store.last_commit_time( @domain_class, @pk_id )
			last_commit_time && last_commit_time > @d_obj_retrieve_time
		end
		
		def to_s
			db_object.to_s
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
		
		@@db_bridge = nil
			
		def self.db_bridge; @@db_bridge ||= DbBridge.new; end
			
		def self.db_name= (dbName) #:nodoc:
			DbConnection.db_name= dbName
		end
		
		def initialize #:nodoc:
			@cache = ObjectStore::Cache.new self.class.db_bridge
		end

		# Returns all domain objects for the given domain class.
		def all(domain_class)
			@cache.get_by_query( Query.new( domain_class ) )
		end

		# Returns the DbBridge; this is useful in case you need to use raw SQL for a
		# specific query.
		def db_bridge; @cache.db_bridge; end
		
		# Returns the domain object corresponding to the domain class and pk_id.
		def get( domain_class, pk_id )
			@cache.get_by_query( Query.new( domain_class, pk_id ) ).first or (
				raise(
					DomainObjectNotFoundError, "Can't find #{domain_class} #{pk_id}",
					caller
				)
			)
		end

		def get_filtered(domain_class_name, searchTerm, fieldName = nil) #:nodoc:
			domain_class = Class.by_name domain_class_name
			unless fieldName
				fieldName = domain_class.link_field( searchTerm.domain_class ).name
			end
			get_subset( Query::Equals.new( fieldName, searchTerm, domain_class ) )
		end

		def get_map_object( domain_class, map1, map2 ) #:nodoc:
			unless map1 && map2
				raise ArgumentError,
						"ObjectStore#get_map_object needs two non-nil keys", caller
			end
			query = Query.infer( domain_class ) { |dobj|
				dobj.send(
					map1.domain_class.basename.camel_case_to_underscore
				).equals( map1 ) &
				dobj.send(
					map2.domain_class.basename.camel_case_to_underscore
				).equals( map2 )
			}
			get_subset( query ).first
		end

		# Retrieves the maximum value across all instances of one domain class.
		#   ObjectStore#get_max( Client )
		# returns the highest +pk_id+ in the +clients+ table.
		#   ObjectStore#get_max( Invoice, "rate" )
		# will return the highest rate for all invoices.
		def get_max( domain_class, field_name = 'pk_id' )
			qry = Query::Max.new( domain_class, field_name )
			@cache.group_query( qry ).only[:max]
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
		
		def method_missing(methodId, *args) #:nodoc:
			if [ :commit, :flush, :last_commit_time ].include?( methodId )
				@cache.send( methodId, *args )
			else
				proc = block_given? ? ( proc { |obj| yield( obj ) } ) : nil
				dispatch = MethodDispatch.new( methodId, proc, *args )
				if dispatch.symbol
					self.send( dispatch.symbol, *dispatch.args )
				else
					super
				end
			end
		end
		
		def mock? #:nodoc:
			false
		end
		
		def query( query ); @cache.group_query( query ); end

		def respond_to?( symbol, include_private = false )
			if MethodDispatch.new( symbol ).symbol
				true
			else
				super
			end
		end
		
		def transaction( &action ); @cache.transaction( action ); end
		
		class Cache #:nodoc:
			attr_reader :db_bridge
			
			def initialize( db_bridge = DbBridge.new )
				@db_bridge = db_bridge
				@domain_class_caches = {}
			end

			def commit( db_object )
				db_object.verify if LafcadioConfig.new()['checkFields'] == 'onCommit'
				db_object.last_commit_type = get_last_commit db_object
				db_object.pre_commit_trigger
				update_dependent_domain_objects( db_object ) if db_object.delete
				@db_bridge.commit db_object
				db_object.pk_id = @db_bridge.last_pk_id_inserted unless db_object.pk_id
				update_after_commit db_object
				db_object.post_commit_trigger
				db_object
			end
			
			def cache( domain_class )
				unless @domain_class_caches[domain_class]
					@domain_class_caches[domain_class] = DomainClassCache.new(
						domain_class, @db_bridge
					)
				end
				@domain_class_caches[domain_class]
			end
			
			def get_last_commit( db_object )
				if db_object.delete
					DomainObject::COMMIT_DELETE
				elsif db_object.pk_id
					DomainObject::COMMIT_EDIT
				else
					DomainObject::COMMIT_ADD
				end
			end

			def method_missing( meth, *args )
				simple_dispatch = [
					:get_by_query, :queries, :save, :set_commit_time,
					:update_after_commit
				]
				if simple_dispatch.include?( meth )
					cache( args.first.domain_class ).send( meth, *args )
				elsif [ :[], :last_commit_time ].include?( meth )
					cache( args.first ).send( meth, *args[1..-1] )
				elsif [ :group_query, :transaction ].include?( meth )
					@db_bridge.send( meth, *args )
				end
			end

			def update_dependent_domain_class( db_object, aClass, field )
				object_store = ObjectStore.get_object_store
				collection = object_store.get_filtered(
					aClass.name, db_object, field.name
				)
				collection.each { |dependentObject|
					if field.delete_cascade
						dependentObject.delete = true
					else
						dependentObject.send( field.name + '=', nil )
					end
					object_store.commit dependentObject
				}
			end

			def update_dependent_domain_objects( db_object )
				dependent_classes = db_object.domain_class.dependent_classes
				dependent_classes.keys.each { |aClass|
					update_dependent_domain_class(
						db_object, aClass, dependent_classes[aClass]
					)
				}
			end
			
			class DomainClassCache < Hash
				attr_reader :commit_times, :domain_class, :queries
				
				def initialize( domain_class, db_bridge )
					super()
					@domain_class, @db_bridge = domain_class, db_bridge
					@commit_times = {}
					@queries = {}
				end

				def []( pk_id )
					dobj = super
					dobj ? dobj.clone : nil
				end
				
				def collect_from_superset( query )
					if ( pk_ids = find_superset_pk_ids( query ) )
						queries[query] = ( pk_ids.collect { |pk_id|
							self[ pk_id ]
						} ).select { |dobj| query.dobj_satisfies?( dobj ) }.collect { |dobj|
							dobj.pk_id
						}
						true
					else
						false
					end
				end
				
				def find_superset_pk_ids( query )
					superset_query, pk_ids =
						queries.find { |other_query, pk_ids|
							query.implies?( other_query )
						}
					pk_ids
				end
				
				# Flushes a domain object.
				def flush( db_object )
					delete db_object.pk_id
					flush_queries
				end
				
				def flush_queries
					queries.keys.each do |query|
						queries.delete( query ) if query.domain_class == domain_class
					end
				end

				def get_by_query( query )
					unless queries[query]
						collected = collect_from_superset query
						if !collected and queries.values
							query_db query
						end
					end
					collection = []
					queries[query].each { |pk_id|
						dobj = self[ pk_id ]
						collection << dobj if dobj
					}
					collection
				end

				def last_commit_time( pk_id ); commit_times[pk_id]; end
				
				def query_db( query )
					newObjects = @db_bridge.select_dobjs query
					newObjects.each { |dbObj| save dbObj }
					queries[query] = newObjects.collect { |dobj| dobj.pk_id }
				end
							
				# Saves a domain object.
				def save(db_object)
					self[db_object.pk_id] = db_object
					flush_queries
				end
			
				def set_commit_time( d_obj ); commit_times[d_obj.pk_id] = Time.now; end

				def update_after_commit( db_object ) #:nodoc:
					if [ DomainObject::COMMIT_EDIT, DomainObject::COMMIT_ADD ].include?(
						db_object.last_commit_type
					)
						save db_object
					elsif db_object.last_commit_type == DomainObject::COMMIT_DELETE
						flush db_object
					end
					set_commit_time db_object
				end
			end
		end

		class CommitSqlStatementsAndBinds < Array #:nodoc:
			attr_reader :bind_values
	
			def initialize( obj )
				@obj = obj
				reversed = []
				@obj.class.self_and_concrete_superclasses.each { |domain_class|
					reversed << statement_bind_value_pair( domain_class )
				}
				reversed.reverse.each do |statement, binds|
					self << [ statement, binds ]
				end
			end
	
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
							nameValues << field.value_for_sql( value )
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
			
			def commit(db_object)
				statements_and_binds = ObjectStore::CommitSqlStatementsAndBinds.new(
					db_object
				)
				statements_and_binds.each do |sql, binds|
					@db_conn.do( sql, *binds )
				end
				if statements_and_binds[0].first =~ /insert/
					sql = 'select last_insert_id()'
					result = select_all( sql )
					@@last_pk_id_inserted = result[0]['last_insert_id()'].to_i
				end
			end
			
			def group_query( query )
				select_all( query.to_sql ).map { |row| query.result_row( row ) }
			end
	
			def last_pk_id_inserted; @@last_pk_id_inserted; end
			
			def maybe_log(sql)
				config = LafcadioConfig.new
				if config['logSql'] == 'y'
					sqllog = Log4r::Logger['sql'] || Log4r::Logger.new( 'sql' )
					filename = File.join(
						config['logdir'], config['sqlLogFile'] || 'sql'
					)
					outputter = Log4r::FileOutputter.new(
						'outputter', { :filename => filename }
					)
					sqllog.outputters = outputter
					sqllog.info sql
				end
			end
			
			def select_all(sql)
				maybe_log sql
				begin
					@db_conn.select_all( sql )
				rescue DBI::DatabaseError => e
					raise $!.to_s + ": #{ e.errstr }"
				end	
			end
			
			def select_dobjs(query)
				domain_class = query.domain_class
				select_all( query.to_sql ).collect { |row_hash|
					domain_class.new( SqlToRubyValues.new( domain_class, row_hash ) )
				}
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
			@@conn_class = DBI
			@@db_name = nil
	
			def self.connection_class=( aClass ); @@conn_class = aClass; end
	
			def self.db_name=( db_name ); @@db_name = db_name; end
	
			def initialize; @dbh = load_new_dbh; end
		
			def disconnect; @dbh.disconnect; end
			
			def load_new_dbh
				config = LafcadioConfig.new
				dbName = @@db_name || config['dbname']
				dbAndHost = nil
				if dbName && config['dbhost']
					dbAndHost = "dbi:Mysql:#{ dbName }:#{ config['dbhost'] }"
				else
					dbAndHost = "dbi:#{config['dbconn']}"
				end
				dbh = @@conn_class.connect(
					dbAndHost, config['dbuser'], config['dbpassword']
				)
				dbh['AutoCommit'] = false
				dbh
			end
			
			def method_missing( symbol, *args )
				@dbh.send( symbol, *args )
			end
		end
	
		class MethodDispatch #:nodoc:
			attr_reader :symbol, :args
		
			def initialize( orig_method, *other_args )
				@orig_method = orig_method
				@orig_args = other_args
				@maybe_proc = @orig_args.shift if @orig_args.size > 0
				@methodName = orig_method.id2name
				dispatch_get_method if @methodName =~ /^get(.*)$/
			end
			
			def camel_case_method_name_after_get
				@orig_method.id2name =~ /^get(.*)$/
				$1.underscore_to_camel_case
			end
			
			def dispatch_all
				@symbol = :all
				@args = [ @domain_class ]
			end
			
			def dispatch_get_filtered( searchTerm, fieldName )
				@symbol = :get_filtered
				@args = [ @domain_class.name, searchTerm, fieldName ]
			end

			def dispatch_get_map_object( domain_class )
				@symbol = :get_map_object
				@args = [ domain_class, @orig_args[0], @orig_args[1] ]
			end

			def dispatch_get_method
				unless ( dispatch_get_singular )
					domain_class_name = camel_case_method_name_after_get.singular
					begin
						@domain_class = Module.by_name domain_class_name
						dispatch_get_plural
					rescue NameError
						# skip it
					end
				end
			end
			
			def dispatch_get_plural
				if @orig_args.size == 0 && @maybe_proc.nil?
					dispatch_all
				else
					searchTerm, fieldName = @orig_args[0..1]
					if searchTerm.nil? && @maybe_proc.nil? && fieldName.nil?
						raise_get_plural_needs_field_arg_if_first_arg_nil
					elsif !@maybe_proc.nil? && searchTerm.nil?
						dispatch_get_plural_by_query_block
					elsif @maybe_proc.nil? && ( !( searchTerm.nil? && fieldName.nil? ) )
						dispatch_get_filtered( searchTerm, fieldName )
					else
						raise_get_plural_cant_have_both_query_block_and_search_term
					end
				end
			end
			
			def dispatch_get_plural_by_query_block
				inferrer = Query::Inferrer.new( @domain_class ) { |obj|
					@maybe_proc.call( obj )
				}
				@symbol = :get_subset
				@args = [ inferrer.execute ]
			end

			def dispatch_get_singular
				begin
					domain_class = Module.by_name camel_case_method_name_after_get
					if @orig_args[0].class <= Integer
						@symbol = :get
						@args = [ domain_class, @orig_args[0] ]
					elsif @orig_args[0].class <= DomainObject
						dispatch_get_map_object domain_class
					elsif @orig_args.empty?
						@symbol = :get
					end
					true
				rescue NameError
					false
				end
			end
			
			def raise_get_plural_needs_field_arg_if_first_arg_nil
				msg = "ObjectStore\##{ @orig_method } needs a field name as its " +
				      "second argument if its first argument is nil"
				raise( ArgumentError, msg, caller )
			end
			
			def raise_get_plural_cant_have_both_query_block_and_search_term
				raise(
					ArgumentError, "Shouldn't send both a query block and a search term",
					caller
				)
			end
		end

		class SqlToRubyValues #:nodoc:
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
end