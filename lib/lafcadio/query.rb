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
#   first_three_invs = object_store.getInvoices { |inv| inv.pkId.in( 1, 2, 3 ) }
#   # => "select * from invoices where pkId in ( 1, 2, 3 )"
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

require 'lafcadio/includer'
Includer.include( 'query' )

module Lafcadio
	class Query
		def self.And( *conditions ); CompoundCondition.new( *conditions ); end
		
		def self.Or( *conditions )
			conditions << CompoundCondition::OR
			CompoundCondition.new( *conditions)
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

			def initialize(fieldName, searchTerm, objectType, compareType)
				super fieldName, searchTerm, objectType
				@compareType = compareType
			end

			def toSql
				useFieldForSqlValue = ( @fieldName != @objectType.sqlPrimaryKeyName &&
				                        !( getField.class <= LinkField ) )
				search_val = ( useFieldForSqlValue ?
				               getField.valueForSQL(@searchTerm).to_s :
				               @searchTerm.to_s )
				"#{ dbFieldName } #{ @@comparators[@compareType] } " + search_val
			end

			def objectMeets(anObj)
				value = anObj.send @fieldName
				value = value.pkId if value.class <= DomainObject
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
				@objectType = conditions[0].objectType
			end

			def objectMeets(anObj)
				if @compoundType == AND
					@conditions.inject( true ) { |result, cond|
						result && cond.objectMeets( anObj )
					}
				else
					@conditions.inject( false ) { |result, cond|
						result || cond.objectMeets( anObj )
					}
				end
			end

			def toSql
				booleanString = @compoundType == AND ? 'and' : 'or'
				subSqlStrings = @conditions.collect { |cond| cond.toSql }
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
				if fieldName == 'pkId'
					ObjectFieldImpostor.new( self, fieldName )
				else
					begin
						classField = @domainClass.getField( fieldName )
						ObjectFieldImpostor.new( self, classField )
					rescue MissingError
						super( methId, *args )
					end
				end
			end
		end
		
		class Equals < Condition #:nodoc:
			def r_val_string
				if primaryKeyField?
					@searchTerm.to_s
				else
					field = getField
					if @searchTerm.class <= ObjectField
						@searchTerm.db_table_and_field_name
					else
						field.valueForSQL(@searchTerm).to_s
					end
				end
			end

			def objectMeets(anObj)
				if @fieldName == @objectType.sqlPrimaryKeyName
					object_value = anObj.pkId
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

			def toSql
				sql = "#{ dbFieldName } "
				unless @searchTerm.nil?
					sql += "= " + r_val_string
				else
					sql += "is null"
				end
				sql
			end
		end

		class In < Condition #:nodoc:
			def self.searchTermType
				Array
			end

			def objectMeets(anObj)
				value = anObj.send @fieldName
				@searchTerm.index(value) != nil
			end

			def toSql
				"#{ dbFieldName } in (#{ @searchTerm.join(', ') })"
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
					fieldName, searchTerm, objectType, matchType = PRE_AND_POST)
				super fieldName, searchTerm, objectType
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

			def objectMeets(anObj)
				value = anObj.send @fieldName
				if value.class <= DomainObject || value.class == DomainObjectProxy
					value = value.pkId.to_s
				end
				if value.class <= Array
					(value.index(@searchTerm) != nil)
				else
					get_regexp.match(value) != nil
				end
			end

			def toSql
				withWildcards = @searchTerm
				if @matchType == PRE_AND_POST
					withWildcards = "%" + withWildcards + "%"
				elsif @matchType == PRE_ONLY
					withWildcards = "%" + withWildcards
				elsif @matchType == POST_ONLY
					withWildcards += "%"
				end
				"#{ dbFieldName } like '#{ withWildcards }'"
			end
		end

		class Link < Condition #:nodoc:
			def self.searchTermType
				DomainObject
			end

			def objectMeets(anObj)
				value = anObj.send @fieldName
				value ? value.pkId == @searchTerm.pkId : false
			end

			def toSql
				"#{ dbFieldName } = #{ @searchTerm.pkId }"
			end
		end

		class Max < Query #:nodoc:
			attr_reader :field_name
		
			def initialize( objectType, field_name = 'pkId' )
				super( objectType )
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
				"max(#{ @field_name })"
			end
		end

		class Not < Condition #:nodoc:
			def initialize(unCondition)
				@unCondition = unCondition
			end

			def objectMeets(obj)
				!@unCondition.objectMeets(obj)
			end
			
			def objectType; @unCondition.objectType; end

			def toSql
				"!(#{ @unCondition.toSql })"
			end
		end

		class ObjectFieldImpostor #:nodoc:
			def ObjectFieldImpostor.comparators
				{ 
					'lt' => Compare::LESS_THAN, 'lte' => Compare::LESS_THAN_OR_EQUAL,
					'gte' => Compare::GREATER_THAN_OR_EQUAL,
					'gt' => Compare::GREATER_THAN
				}
			end
			
			attr_reader :class_field
		
			def initialize( domainObjectImpostor, class_field_or_name )
				@domainObjectImpostor = domainObjectImpostor
				if class_field_or_name == 'pkId'
					@db_field_name = 'pkId'
				else
					@class_field = class_field_or_name
					@db_field_name = class_field_or_name.dbFieldName
				end
			end
			
			def method_missing( methId, *args )
				methodName = methId.id2name
				if !ObjectFieldImpostor.comparators.keys.index( methodName ).nil?
					registerCompareCondition( methodName, *args )
				else
					super( methId, *args )
				end
			end
			
			def registerCompareCondition( compareStr, searchTerm)
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