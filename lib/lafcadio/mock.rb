require 'lafcadio/objectStore'
require 'lafcadio/util'

module Lafcadio
	class MockDbBridge #:nodoc:
		attr_reader :last_pk_id_inserted

		def initialize
			@objects = {}
			@next_pk_ids = {}
			@queries = []
		end

		def all( domain_class )
			@objects[domain_class] ? @objects[domain_class].values : []
		end
		
		def select_dobjs(query)
			@queries << query
			domain_class = query.domain_class
			objects = []
			all( domain_class ).each { |dbObj|
				objects << dbObj if query.dobj_satisfies?( dbObj )
			}
			objects = order_collection( objects, query )
			if (range = query.limit); objects = objects[range]; end
			objects
		end

		def commit(db_object)
			if db_object.pk_id and !db_object.pk_id.is_a?( Integer )
				raise ArgumentError
			end
			objects_by_domain_class = objects_by_domain_class db_object.domain_class
			if db_object.delete
				objects_by_domain_class.delete( db_object.pk_id )
			else
				object_pk_id = pre_commit_pk_id( db_object )
				objects_by_domain_class[object_pk_id] = db_object
			end
		end
				
		def group_query( query )
			query.collect objects_by_domain_class( query.domain_class ).values
		end
		
		def next_pk_id( domain_class )
			dobjs = objects_by_domain_class( domain_class ).values
			dobjs.inject( 0 ) { |memo, obj| memo > obj.pk_id ? memo : obj.pk_id } + 1
		end

		def objects_by_domain_class( domain_class )
			@objects[domain_class] = {} unless @objects[domain_class]
			@objects[domain_class]
		end

		def order_collection( objects, query )
			objects = objects.sort_by { |dobj|
				if ( order_by = query.order_by ).nil?
					dobj.pk_id
				elsif order_by.is_a?( Array )
					order_by.map { |field_name| dobj.send( field_name ) }
				else
					dobj.send order_by
				end
			}
			objects.reverse! if query.order_by_order == Query::DESC
			objects
		end
		
		def pre_commit_pk_id( domain_object )
			@next_pk_ids = {} unless @next_pk_ids
			if (next_pk_id = @next_pk_ids[domain_object.domain_class])
				@next_pk_ids[domain_object.domain_class] = nil
				@last_pk_id_inserted = next_pk_id
			elsif domain_object.pk_id
				domain_object.pk_id
			elsif ( next_pk_id = @next_pk_ids[domain_object.domain_class] )
				@last_pk_id_inserted = next_pk_id
				@next_pk_ids[domain_object.domain_class] = nil
				next_pk_id
			else
				pk_ids = objects_by_domain_class( domain_object.domain_class ).keys
				@last_pk_id_inserted = pk_ids.max ? pk_ids.max + 1 : 1
			end
		end

		def queries( domain_class = nil )
			@queries.select { |qry|
				domain_class ? qry.domain_class == domain_class : true
			}
		end
		
		def query_count( sql )
			@queries.select { |qry| qry.to_sql == sql }.size
		end
		
		def set_next_pk_id( domain_class, npi )
			@next_pk_ids = {} unless @next_pk_ids
			@next_pk_ids[ domain_class ] = npi
		end
	end

	# Externally, the MockObjectStore looks and acts exactly like the ObjectStore,
	# but stores all its data in memory. This makes it very useful for unit
	# testing, and in fact LafcadioTestCase#setup creates a new instance of
	# MockObjectStore for each test case. For example:
	#
	#   class SomeTestCase < Test::Unit::TestCase
	#     def setup
	#       @mock_object_store = Lafcadio::MockObjectStore.new
	#       Lafcadio::ObjectStore.set_object_store @mock_object_store
	#     end
	#   end
	class MockObjectStore < ObjectStore
		def self.db_bridge #:nodoc:
			MockDbBridge.new
		end
		
		public_class_method :new

		def mock? # :nodoc:
			true
		end
	end
end
