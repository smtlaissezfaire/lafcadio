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

require 'delegate'

module Lafcadio
	class Query
		def self.And( *conditions ); CompoundCondition.new( *conditions ); end
		
		def self.infer( domain_class, &action )
			inferrer = Query::Inferrer.new( domain_class ) { |obj|
				action.call( obj )
			}
			inferrer.execute
		end
		
		def self.Or( *conditions )
			conditions << CompoundCondition::OR
			CompoundCondition.new( *conditions)
		end

		ASC		= 1
		DESC 	= 2

		attr_reader :domain_class, :condition
		attr_accessor :order_by, :order_by_order, :limit

		def initialize(domain_class, pk_idOrCondition = nil)
			@domain_class = domain_class
			( @condition, @order_by, @limit ) = [ nil, nil, nil ]
			if pk_idOrCondition
				if pk_idOrCondition.class <= Condition
					@condition = pk_idOrCondition
				else
					@condition = Query::Equals.new( 'pk_id', pk_idOrCondition,
					                                domain_class )
				end
			end
			@order_by_order = ASC
		end
		
		def and( &action ); compound( CompoundCondition::AND, action ); end
		
		def compound( comp_type, action )
			rquery = Query.infer( @domain_class ) { |dobj| action.call( dobj ) }
			comp_cond = Query::CompoundCondition.new( @condition, rquery.condition,
			                                          comp_type )
			comp_cond.query
		end
		
		def eql?( other ); other.class <= Query && other.to_sql == to_sql; end

		def fields; '*'; end

		def hash; to_sql.hash; end
		
		def limit_clause
			"limit #{ @limit.begin }, #{ @limit.end - @limit.begin + 1 }" if @limit
		end
		
		def object_meets( dobj ); @condition.object_meets( dobj ); end

		def or( &action ); compound( CompoundCondition::OR, action ); end
		
		def order_clause
			if @order_by
				order_by_field = @domain_class.get_field( @order_by )
				clause = "order by #{ order_by_field.db_field_name } "
				clause += @order_by_order == ASC ? 'asc' : 'desc'
				clause
			end
		end
		
		def implies?( other_query )
			if other_query == self
				true
			elsif @domain_class == other_query.domain_class
				if other_query.condition.nil? and !self.condition.nil?
					true
				else
					self.condition and self.condition.implies?( other_query.condition )
				end
			end
		end

		def sql_primary_key_field(domain_class)
			"#{ domain_class.table_name }.#{ domain_class.sql_primary_key_name }"
		end

		def tables
			concrete_classes = domain_class.self_and_concrete_superclasses.reverse
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
			concrete_classes = domain_class.self_and_concrete_superclasses.reverse
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

			attr_reader :domain_class

			def initialize(fieldName, searchTerm, domain_class)
				@fieldName = fieldName
				@searchTerm = searchTerm
				unless @searchTerm.class <= self.class.search_term_type
					raise "Incorrect searchTerm type #{ searchTerm.class }"
				end
				@domain_class = domain_class
				if @domain_class
					unless @domain_class <= DomainObject
						raise "Incorrect object type #{ @domain_class.to_s }"
					end
				end
			end
			
			def implies?( other_condition )
				self.eql?( other_condition ) or (
					other_condition.respond_to?( :implied_by? ) and 
							other_condition.implied_by?( self )
				)
			end
			
			def db_field_name; get_field.db_table_and_field_name; end
			
			def eql?( other_cond )
				other_cond.is_a?( Condition ) and other_cond.to_sql == to_sql
			end
			
			def get_field; @domain_class.get_field( @fieldName ); end
			
			def query; Query.new( @domain_class, self ); end
			
			def not
				Query::Not.new( self )
			end

			def primary_key_field?; 'pk_id' == @fieldName; end
			
			def to_condition; self; end
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

			def initialize(fieldName, searchTerm, domain_class, compareType)
				super fieldName, searchTerm, domain_class
				@compareType = compareType
			end

			def to_sql
				if ( get_field.kind_of?( DomainObjectField ) &&
				     !@searchTerm.respond_to?( :pk_id ) )
					search_val = @searchTerm.to_s
				else
					search_val = get_field.value_for_sql( @searchTerm ).to_s
				end
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
			
			def initialize( *args )
				if( [ AND, OR ].index( args.last) )
					@compound_type = args.last
					args.pop
				else
					@compound_type = AND
				end
				@conditions = args.map { |arg|
					arg.respond_to?( :to_condition ) ? arg.to_condition : arg
				}
				@domain_class = @conditions[0].domain_class
			end

			def implied_by?( other_condition )
				@compound_type == OR && @conditions.any? { |cond|
					cond.implies?( other_condition )
				}
			end
			
			def implies?( other_condition )
				super( other_condition ) or (
					@compound_type == AND and @conditions.any? { |cond|
						cond.implies?( other_condition )
					}
				) or (
					@compound_type == OR and @conditions.all? { |cond|
						cond.implies?( other_condition )
					}
				)
			end

			def object_meets(anObj)
				if @compound_type == AND
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
				booleanString = @compound_type == AND ? 'and' : 'or'
				subSqlStrings = @conditions.collect { |cond| cond.to_sql }
				"(#{ subSqlStrings.join(" #{ booleanString } ") })"
			end
		end

		module DomainObjectImpostor #:nodoc:
			@@impostor_classes = {}
			
			def self.impostor( domain_class )
				unless @@impostor_classes[domain_class]
					i_class = Class.new
					i_class.module_eval <<-CLASS_DEF
						attr_reader :domain_class
						
						def initialize; @domain_class = #{ domain_class.name }; end
						
						def method_missing( methId, *args )
							fieldName = methId.id2name
							begin
								classField = self.domain_class.get_field( fieldName )
								ObjectFieldImpostor.new( self, classField )
							rescue MissingError
								super( methId, *args )
							end
						end
						
						#{ domain_class.name }.class_fields.each do |class_field|
							begin
								undef_method class_field.name.to_sym
							rescue NameError
								# not defined globally or in an included Module, skip it
							end
						end
					CLASS_DEF
					@@impostor_classes[domain_class] = i_class
				end
				i_class = @@impostor_classes[domain_class]
				i_class.new
			end
		end
		
		class Equals < Condition #:nodoc:
			def r_val_string
				field = get_field
				if @searchTerm.class <= ObjectField
					@searchTerm.db_table_and_field_name
				else
					begin
						field.value_for_sql( @searchTerm ).to_s
					rescue DomainObjectInitError
						raise(
							ArgumentError,
							"Can't query using an uncommitted domain object as a search " +
									"term.",
							caller
						)
					end
				end
			end

			def object_meets(anObj)
				if @searchTerm.class <= ObjectField
					compare_value = anObj.send( @searchTerm.name )
				else
					compare_value = @searchTerm
				end
				compare_value == anObj.send( @fieldName )
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
				if get_field.is_a?( StringField )
					quoted = @searchTerm.map do |str| "'#{ str }'"; end
					end_clause = quoted.join ', '
				else
					end_clause = @searchTerm.join ', '
				end
				"#{ db_field_name } in (#{ end_clause })"
			end
		end
		
		class Include < CompoundCondition
			def initialize( field_name, search_term, domain_class )
				begin_cond = Like.new( field_name, search_term + ',', domain_class,
				                       Like::POST_ONLY )
				mid_cond = Like.new( field_name, ',' + search_term + ',',
				                     domain_class )
				end_cond = Like.new( field_name, ',' + search_term, domain_class,
				                     Like::PRE_ONLY )
				only_cond = Equals.new( field_name, search_term, domain_class )
				super( begin_cond, mid_cond, end_cond, only_cond, OR )
			end
		end

		class Inferrer #:nodoc:
			def initialize( domain_class, &action )
				@domain_class = domain_class; @action = action
			end
			
			def execute
				impostor = DomainObjectImpostor.impostor( @domain_class )
				condition = @action.call( impostor ).to_condition
				query = Query.new( @domain_class, condition )
			end
		end
		
		class Like < Condition #:nodoc:
			PRE_AND_POST	= 1
			PRE_ONLY			= 2
			POST_ONLY			= 3

			def initialize(
					fieldName, searchTerm, domain_class, matchType = PRE_AND_POST)
				super fieldName, searchTerm, domain_class
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

		class Max < Query #:nodoc:
			attr_reader :field_name
		
			def initialize( domain_class, field_name = 'pk_id' )
				super( domain_class )
				@field_name = field_name
			end
		
			def collect( coll )
				max = coll.inject( nil ) { |max, d_obj|
					a_value = d_obj.send( @field_name )
					( max.nil? || a_value > max ) ? a_value : max
				}
				[ max ]
			end
		
			def fields
				"max(#{ @domain_class.get_field( @field_name ).db_field_name })"
			end
		end

		class Not < Condition #:nodoc:
			def initialize(unCondition)
				@unCondition = unCondition
			end

			def object_meets(obj)
				!@unCondition.object_meets(obj)
			end
			
			def domain_class; @unCondition.domain_class; end

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
					@field_name = 'pk_id'
				else
					@class_field = class_field_or_name
					@field_name = class_field_or_name.name
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
				Compare.new( @field_name, searchTerm,
				             @domainObjectImpostor.domain_class, compareVal )
			end
			
			def equals( searchTerm )
				Equals.new( @field_name, field_or_field_name( searchTerm ),
					          @domainObjectImpostor.domain_class )
			end
			
			def field_or_field_name( search_term )
				if search_term.class == ObjectFieldImpostor
					search_term.class_field
				else
					search_term
				end
			end
			
			def include?( search_term )
				if @class_field.instance_of?( TextListField )
					Include.new( @field_name, search_term,
					             @domainObjectImpostor.domain_class )
				else
					raise ArgumentError
				end
			end
			
			def like( regexp )
				if regexp.is_a?( Regexp )
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
					Query::Like.new( @field_name, searchTerm,
													 @domainObjectImpostor.domain_class, matchType )
				else
					raise(
						ArgumentError, "#{ @field_name }#like needs to receive a Regexp",
						caller
					)
				end
			end
			
			def in( *searchTerms )
				Query::In.new( @field_name, searchTerms,
											 @domainObjectImpostor.domain_class )
			end
			
			def nil?; equals( nil ); end
			
			def to_condition
				if @class_field.instance_of?( BooleanField )
					Query::Equals.new( @field_name, true,
					                   @domainObjectImpostor.domain_class )
				else
					raise
				end
			end
			
			def not; to_condition.not; end
		end
	end
end