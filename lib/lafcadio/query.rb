# = Overview
# By passing a block to ObjectStore, you can write complex, ad-hoc queries in
# Ruby. This involves a few more keystrokes than writing raw SQL, but also makes
# it easier to change queries at runtime, and these queries can also be fully
# tested against the MockObjectStore.
#   big_invoices = object_store.getInvoices { |inv| inv.rate.gt( 50 ) }
#   # => "select * from invoices where rate > 50"
# This a full-fledged block, so you can pass in values from the calling context.
#   date = Date.new( 2004, 1, 1 )
#   recent_invoices = object_store.getInvoices { |inv| inv.date.gt( date ) }
#   # => "select * from invoices where date > '2004-01-01'"
# 
# = Query operators
# You can compare fields either to simple values, or to other fields in the same
# table.
#   paid_immediately = object_store.getInvoices { |inv|
#     inv.date.equals( inv.paid )
#   }
#   # => "select * from invoices where date = paid"
#
# == Numerical comparisons: +lt+, +lte+, +gte+, +gt+
# +lt+, +lte+, +gte+, and +gt+ stand for "less than", "less than or equal",
# "greater than or equal", and "greater than", respectively.
#   tiny_invoices = object_store.getInvoices { |inv| inv.rate.lte( 25 ) }
#   # => "select * from invoices where rate <= 25"
# These comparators work on fields that contain numbers, dates, and even
# references to other domain objects.
#   for_1st_ten_clients = object_store.getInvoices { |inv|
#     inv.client.lte( 10 )
#   }
#   # => "select * from invoices where client <= 10"
#
# == Equality: +equals+
#   full_week_invs = object_store.getInvoices { |inv| inv.hours.equals( 40 ) }
#   # => "select * from invoices where hours = 40"
# If you're comparing to a domain object you should pass in the object itself.
#   client = object_store.getClient( 99 )
#   invoices = object_store.getInvoices { |inv| inv.client.equals( client ) }
#   # => "select * from invoices where client = 99"
# 
# == Inclusion: +in+
#   first_three_invs = object_store.getInvoices { |inv| inv.pk_id.in( 1, 2, 3 ) }
#   # => "select * from invoices where pk_id in ( 1, 2, 3 )"
#
# == Text comparison: +like+
#   fname_starts_with_a = object_store.getUsers { |user|
#     user.fname.like( /^a/ )
#   }
#   # => "select * from users where fname like 'a%'"
#   fname_ends_with_a = object_store.getUsers { |user|
#     user.fname.like( /a$/ )
#   }
#   # => "select * from users where fname like '%a'"
#   fname_contains_a = object_store.getUsers { |user|
#     user.fname.like( /a/ )
#   }
#   # => "select * from users where fname like '%a%'"
# Please note that although we're using the Regexp operators here, these aren't
# full-fledged regexps. Only ^ and $ work for this.
#
# == Compound conditions: <tt>Query.And</tt> and <tt>Query.Or</tt>
#   invoices = object_store.getInvoices { |inv|
#     Query.And( inv.hours.equals( 40 ), inv.rate.equals( 50 ) )
#   }
#   # => "select * from invoices where (hours = 40 and rate = 50)"
#   client99 = object_store.getClient( 99 )
#   invoices = object_store.getInvoices { |inv|
#     Query.Or( inv.hours.equals( 40 ),
#               inv.rate.equals( 50 ),
#               inv.client.equals( client99 ) )
#   }
#   # => "select * from invoices where (hours = 40 or rate = 50 or client = 99)"
# Note that both compound operators can take 2 or more arguments. Also, they can
# be nested:
#   invoices = object_store.getInvoices { |inv|
#     Query.And( inv.hours.equals( 40 ),
#                Query.Or( inv.rate.equals( 50 ),
#                          inv.client.equals( client99 ) ) )
#   }
#   # => "select * from invoices where (hours = 40 and 
#   #     (rate = 50 or client = 99))"
#
# == Negation: +not+
#   invoices = object_store.getInvoices { |inv| inv.rate.equals( 50 ).not }
#   # => "select * from invoices where rate != 50"

module Lafcadio
	class Query
		def self.And( *conditions ); CompoundCondition.new( *conditions ); end
		
		def self.Or( *conditions )
			conditions << CompoundCondition::OR
			CompoundCondition.new( *conditions)
		end

		ASC		= 1
		DESC 	= 2

		attr_reader :object_type, :condition
		attr_accessor :orderBy, :orderByOrder, :limit

		def initialize(object_type, pk_idOrCondition = nil)
			@object_type = object_type
			( @condition, @orderBy, @limit ) = [ nil, nil, nil ]
			if pk_idOrCondition
				if pk_idOrCondition.class <= Condition
					@condition = pk_idOrCondition
				else
					@condition = Query::Equals.new( object_type.sql_primary_key_name,
					                                pk_idOrCondition, object_type )
				end
			end
			@orderByOrder = ASC
		end
		
		def eql?( other ); other.class <= Query && other.to_sql == to_sql; end

		def fields; '*'; end

		def hash; to_sql.hash; end
		
		def limit_clause
			"limit #{ @limit.begin }, #{ @limit.end - @limit.begin + 1 }" if @limit
		end

		def order_clause
			if @orderBy
				clause = "order by #{ @orderBy } "
				clause += @orderByOrder == ASC ? 'asc' : 'desc'
				clause
			end
		end

		def sql_primary_key_field(object_type)
			"#{ object_type.table_name }.#{ object_type.sql_primary_key_name }"
		end

		def tables
			concrete_classes = object_type.self_and_concrete_superclasses.reverse
			table_names = concrete_classes.collect { |domain_class|
				domain_class.table_name
			}
			table_names.join( ', ' )
		end

		def to_sql
			clauses = [ "select #{ fields }", "from #{ tables }" ]
			clauses << where_clause if where_clause
			clauses << order_clause if order_clause
			clauses << limit_clause if limit_clause
			clauses.join ' '
		end

		def where_clause
			concrete_classes = object_type.self_and_concrete_superclasses.reverse
			where_clauses = []
			concrete_classes.each_with_index { |domain_class, i|
				if i < concrete_classes.size - 1
					join_clause = sql_primary_key_field( domain_class ) + ' = ' +
					              sql_primary_key_field( concrete_classes[i+1] )
					where_clauses << join_clause
				else
					where_clauses << @condition.to_sql if @condition
				end
			}
			where_clauses.size > 0 ? 'where ' + where_clauses.join( ' and ' ) : nil
		end

		class Condition #:nodoc:
			def Condition.search_term_type
				Object
			end

			attr_reader :object_type

			def initialize(fieldName, searchTerm, object_type)
				@fieldName = fieldName
				@searchTerm = searchTerm
				unless @searchTerm.class <= self.class.search_term_type
					raise "Incorrect searchTerm type #{ searchTerm.class }"
				end
				@object_type = object_type
				if @object_type
					unless @object_type <= DomainObject
						raise "Incorrect object type #{ @object_type.to_s }"
					end
				end
			end
			
			def db_field_name
				if primary_key_field?
					db_table = @object_type.table_name
					db_field_name = @object_type.sql_primary_key_name
					"#{ db_table }.#{ db_field_name }"
				else
					get_field.db_table_and_field_name
				end
			end
			
			def get_field
				anObjectType = @object_type
				field = nil
				while (anObjectType < DomainObject || anObjectType < DomainObject) &&
							!field
					field = anObjectType.get_class_field @fieldName
					anObjectType = anObjectType.superclass
				end
				if field
					field
				else
					errStr = "Couldn't find field \"#{ @fieldName }\" in " +
									 "#{ @object_type } domain class"
					raise( MissingError, errStr, caller )
				end
			end
			
			def not
				Query::Not.new( self )
			end

			def primary_key_field?
				[ @object_type.sql_primary_key_name, 'pk_id' ].include?( @fieldName )
			end
		end

		class Compare < Condition #:nodoc:
			LESS_THAN							= 1
			LESS_THAN_OR_EQUAL		= 2
			GREATER_THAN_OR_EQUAL = 3
			GREATER_THAN					= 4

			@@comparators = {
				LESS_THAN => '<',
				LESS_THAN_OR_EQUAL => '<=',
				GREATER_THAN_OR_EQUAL => '>=',
				GREATER_THAN => '>'
			}

			@@mockComparators = {
				LESS_THAN => Proc.new { |d1, d2| d1 < d2 },
				LESS_THAN_OR_EQUAL => Proc.new { |d1, d2| d1 <= d2 },
				GREATER_THAN_OR_EQUAL => Proc.new { |d1, d2| d1 >= d2 },
				GREATER_THAN => Proc.new { |d1, d2| d1 > d2 }
			}

			def initialize(fieldName, searchTerm, object_type, compareType)
				super fieldName, searchTerm, object_type
				@compareType = compareType
			end

			def to_sql
				not_pk = @fieldName != @object_type.sql_primary_key_name
				use_field_for_sql_value = ( not_pk &&
				                            ( !( get_field.class <= LinkField ) ||
																		  @searchTerm.respond_to?( :object_type ) ) )
				search_val = ( use_field_for_sql_value ?
				               get_field.value_for_sql( @searchTerm ).to_s :
											 @searchTerm.to_s )
				"#{ db_field_name } #{ @@comparators[@compareType] } " + search_val
			end

			def object_meets(anObj)
				value = anObj.send @fieldName
				value = value.pk_id if value.class <= DomainObject
				if value
					@@mockComparators[@compareType].call(value, @searchTerm)
				else
					false
				end
			end
		end

		class CompoundCondition < Condition #:nodoc:
			AND = 1
			OR  = 2
		
			def initialize(*conditions)
				if( [ AND, OR ].index(conditions.last) )
					@compoundType = conditions.last
					conditions.pop
				else
					@compoundType = AND
				end
				@conditions = conditions
				@object_type = conditions[0].object_type
			end

			def object_meets(anObj)
				if @compoundType == AND
					@conditions.inject( true ) { |result, cond|
						result && cond.object_meets( anObj )
					}
				else
					@conditions.inject( false ) { |result, cond|
						result || cond.object_meets( anObj )
					}
				end
			end

			def to_sql
				booleanString = @compoundType == AND ? 'and' : 'or'
				subSqlStrings = @conditions.collect { |cond| cond.to_sql }
				"(#{ subSqlStrings.join(" #{ booleanString } ") })"
			end
		end

		class DomainObjectImpostor #:nodoc:
			attr_reader :domainClass
		
			def initialize( domainClass )
				@domainClass = domainClass
			end
			
			def method_missing( methId, *args )
				fieldName = methId.id2name
				if fieldName == 'pk_id'
					ObjectFieldImpostor.new( self, fieldName )
				else
					begin
						classField = @domainClass.get_field( fieldName )
						ObjectFieldImpostor.new( self, classField )
					rescue MissingError
						super( methId, *args )
					end
				end
			end
		end
		
		class Equals < Condition #:nodoc:
			def r_val_string
				if primary_key_field?
					@searchTerm.to_s
				else
					field = get_field
					if @searchTerm.class <= ObjectField
						@searchTerm.db_table_and_field_name
					else
						field.value_for_sql(@searchTerm).to_s
					end
				end
			end

			def object_meets(anObj)
				if @fieldName == @object_type.sql_primary_key_name
					object_value = anObj.pk_id
				else
					object_value = anObj.send @fieldName
				end
				compare_value =
				if @searchTerm.class <= ObjectField
					compare_value = anObj.send( @searchTerm.name )
				else
					compare_value = @searchTerm
				end
				compare_value == object_value
			end

			def to_sql
				sql = "#{ db_field_name } "
				unless @searchTerm.nil?
					sql += "= " + r_val_string
				else
					sql += "is null"
				end
				sql
			end
		end

		class In < Condition #:nodoc:
			def self.search_term_type
				Array
			end

			def object_meets(anObj)
				value = anObj.send @fieldName
				@searchTerm.index(value) != nil
			end

			def to_sql
				"#{ db_field_name } in (#{ @searchTerm.join(', ') })"
			end
		end

		class Inferrer #:nodoc:
			def initialize( domainClass, &action )
				@domainClass = domainClass; @action = action
			end
			
			def execute
				impostor = DomainObjectImpostor.new( @domainClass )
				condition = @action.call( impostor )
				query = Query.new( @domainClass, condition )
			end
		end
		
		class Like < Condition #:nodoc:
			PRE_AND_POST	= 1
			PRE_ONLY			= 2
			POST_ONLY			= 3

			def initialize(
					fieldName, searchTerm, object_type, matchType = PRE_AND_POST)
				super fieldName, searchTerm, object_type
				@matchType = matchType
			end
			
			def get_regexp
				if @matchType == PRE_AND_POST
					Regexp.new(@searchTerm)
				elsif @matchType == PRE_ONLY
					Regexp.new(@searchTerm.to_s + "$")
				elsif @matchType == POST_ONLY
					Regexp.new("^" + @searchTerm)
				end
			end

			def object_meets(anObj)
				value = anObj.send @fieldName
				if value.class <= DomainObject || value.class == DomainObjectProxy
					value = value.pk_id.to_s
				end
				if value.class <= Array
					(value.index(@searchTerm) != nil)
				else
					get_regexp.match(value) != nil
				end
			end

			def to_sql
				withWildcards = @searchTerm
				if @matchType == PRE_AND_POST
					withWildcards = "%" + withWildcards + "%"
				elsif @matchType == PRE_ONLY
					withWildcards = "%" + withWildcards
				elsif @matchType == POST_ONLY
					withWildcards += "%"
				end
				"#{ db_field_name } like '#{ withWildcards }'"
			end
		end

		class Link < Condition #:nodoc:
			def initialize( fieldName, searchTerm, object_type )
				if searchTerm.pk_id.nil?
					raise ArgumentError,
					      "Can't query using an uncommitted domain object as a search term",
								caller
				else
					super( fieldName, searchTerm, object_type )
				end
			end
		
			def self.search_term_type
				DomainObject
			end

			def object_meets(anObj)
				value = anObj.send @fieldName
				value ? value.pk_id == @searchTerm.pk_id : false
			end

			def to_sql
				"#{ db_field_name } = #{ @searchTerm.pk_id }"
			end
		end

		class Max < Query #:nodoc:
			attr_reader :field_name
		
			def initialize( object_type, field_name = nil )
				super( object_type )
				if field_name
					@field_name = field_name
					@pk = false
				else
					@field_name = object_type.sql_primary_key_name
					@pk = true
				end
			end
		
			def collect( coll )
				fn = @pk ? 'pk_id': @field_name
				max = coll.inject( nil ) { |max, d_obj|
					a_value = d_obj.send( fn )
					( max.nil? || a_value > max ) ? a_value : max
				}
				[ max ]
			end
		
			def fields
				"max(#{ @field_name })"
			end
		end

		class Not < Condition #:nodoc:
			def initialize(unCondition)
				@unCondition = unCondition
			end

			def object_meets(obj)
				!@unCondition.object_meets(obj)
			end
			
			def object_type; @unCondition.object_type; end

			def to_sql
				"!(#{ @unCondition.to_sql })"
			end
		end

		class ObjectFieldImpostor #:nodoc:
			def self.comparators
				{ 
					'lt' => Compare::LESS_THAN, 'lte' => Compare::LESS_THAN_OR_EQUAL,
					'gte' => Compare::GREATER_THAN_OR_EQUAL,
					'gt' => Compare::GREATER_THAN
				}
			end
			
			attr_reader :class_field
		
			def initialize( domainObjectImpostor, class_field_or_name )
				@domainObjectImpostor = domainObjectImpostor
				if class_field_or_name == 'pk_id'
					@db_field_name = 'pk_id'
				else
					@class_field = class_field_or_name
					@db_field_name = class_field_or_name.db_field_name
				end
			end
			
			def method_missing( methId, *args )
				methodName = methId.id2name
				if !ObjectFieldImpostor.comparators.keys.index( methodName ).nil?
					register_compare_condition( methodName, *args )
				else
					super( methId, *args )
				end
			end
			
			def register_compare_condition( compareStr, searchTerm)
				compareVal = ObjectFieldImpostor.comparators[compareStr]
				Compare.new( @db_field_name, searchTerm,
										 @domainObjectImpostor.domainClass, compareVal )
			end
			
			def equals( searchTerm )
				Equals.new( @db_field_name, field_or_field_name( searchTerm ),
				            @domainObjectImpostor.domainClass )
			end
			
			def field_or_field_name( search_term )
				if search_term.class == ObjectFieldImpostor
					search_term.class_field
				else
					search_term
				end
			end
			
			def like( regexp )
				if regexp.source =~ /^\^(.*)/
					searchTerm = $1
					matchType = Query::Like::POST_ONLY
				elsif regexp.source =~ /(.*)\$$/
					searchTerm = $1
					matchType = Query::Like::PRE_ONLY
				else
					searchTerm = regexp.source
					matchType = Query::Like::PRE_AND_POST
				end
				Query::Like.new( @db_field_name, searchTerm,
												 @domainObjectImpostor.domainClass, matchType )
			end
			
			def in( *searchTerms )
				Query::In.new( @db_field_name, searchTerms,
											 @domainObjectImpostor.domainClass )
			end
		end
	end
end