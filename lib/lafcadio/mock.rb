require 'lafcadio/objectStore'

module Lafcadio
	class MockDbBridge #:nodoc:
		attr_reader :last_pk_id_inserted, :retrievals_by_type, :query_count

		def initialize
			@objects = {}
			@retrievals_by_type = Hash.new 0
			@query_count = Hash.new( 0 )
			@next_pk_ids = {}
		end

		def commit(db_object)
			if db_object.pk_id and !db_object.pk_id.is_a?( Integer )
				raise ArgumentError
			end
			objects_by_domain_class = get_objects_by_domain_class(
				db_object.domain_class
			)
			if db_object.delete
				objects_by_domain_class.delete( db_object.pk_id )
			else
				object_pk_id = get_pk_id_before_committing( db_object )
				objects_by_domain_class[object_pk_id] = db_object
			end
		end
		
		def _get_all( domain_class )
			@retrievals_by_type[domain_class] = @retrievals_by_type[domain_class] + 1
			@objects[domain_class] ? @objects[domain_class].values : []
		end
		
		def get_collection_by_query(query)
			@query_count[query.to_sql] += 1
			objects = []
			_get_all( query.domain_class ).each { |dbObj|
				if query.condition
					objects << dbObj if query.condition.object_meets(dbObj)
				else
					objects << dbObj
				end
			}
			if ( order_by = query.order_by )
				objects = objects.sort_by { |dobj| dobj.send( order_by ) }
				objects.reverse! if query.order_by_order == Query::DESC
			else
				objects = objects.sort_by { |dobj| dobj.pk_id }
			end
			if (range = query.limit)
				objects = objects[range]
			end
			objects
		end
		
		def get_pk_id_before_committing( db_object )
			if db_object.pk_id
				db_object.pk_id
			else
				if ( next_pk_id = @next_pk_ids[db_object.domain_class] )
					@last_pk_id_inserted = next_pk_id
					@next_pk_ids[db_object.domain_class] = nil
					next_pk_id
				else
					maxpk_id = 0
					pk_ids = get_objects_by_domain_class( db_object.domain_class ).keys
					pk_ids.each { |pk_id|
						maxpk_id = pk_id if pk_id > maxpk_id
					}
					@last_pk_id_inserted = maxpk_id + 1
					@last_pk_id_inserted
				end
			end
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
				dobjs_by_pk_id = @objects[query.domain_class]
				if dobjs_by_pk_id
					dobjs = dobjs_by_pk_id.values.sort_by { |dobj|
						dobj.send( query.field_name )
					}
					[ dobjs.last.send( query.field_name ) ]
				else
					[ nil ]
				end
			end
		end
		
		def set_next_pk_id( domain_class, npi )
			@next_pk_ids[ domain_class ] = npi
		end
	end

	# Externally, the MockObjectStore looks and acts exactly like the ObjectStore,
	# but stores all its data in memory. This makes it very useful for unit
	# testing, and in fact LafcadioTestCase#setup creates a new instance of
	# MockObjectStore for each test case.
	class MockObjectStore < ObjectStore
		public_class_method :new

		def initialize # :nodoc:
			super( MockDbBridge.new )
		end
		
		def mock? # :nodoc:
			true
		end
	end
end
