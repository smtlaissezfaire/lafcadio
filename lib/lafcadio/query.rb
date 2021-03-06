# = Overview
# By passing a block to ObjectStore, you can write complex, ad-hoc queries in
# Ruby. This involves a few more keystrokes than writing raw SQL, but also
# makes it easier to change queries at runtime, and these queries can also be
# fully tested against the MockObjectStore.
#   big_invoices = Invoice.get { |inv| inv.rate.gt( 50 ) }
#   # => runs "select * from invoices where rate > 50"
# This a full-fledged block, so you can pass in values from the calling context.
#   date = Date.new( 2004, 1, 1 )
#   recent_invoices = Invoice.get { |inv| inv.date.gt( date ) }
#   # => runs "select * from invoices where date > '2004-01-01'"
#
# = Building and accessing queries
# To build a query and run it immediately, call DomainObject.get and pass it a
# block:
#   hwangs = User.get { |u| u.lname.equals( 'Hwang' ) }
# You can also call ObjectStore#[ plural domain class ] with a block:
#   hwangs = ObjectStore.get_object_store.users { |u|
#     u.lname.equals( 'Hwang' )
#   }
# If you want more fine-grained control over a query, first create it with
# Query.infer and then build it, using ObjectStore#query to run it.
#   qry = Query.infer( User ) { |u| u.lname.equals( 'Hwang' ) }
#   qry.to_sql # => "select * from users where users.lname = 'Hwang'"
#   qry = qry.and { |u| u.fname.equals( 'Francis' ) }
#   qry.to_sql # => "select * from users where (users.lname = 'Hwang' and
#                    users.fname = 'Francis')"
#   qry.limit = 0..5
#   qry.to_sql # => "select * from users where (users.lname = 'Hwang' and
#                    users.fname = 'Francis') limit 0, 6"
# Using Query.infer, you can also set order_by and order_by_order clauses:
#   qry = Query.infer(
#     SKU,
#     :order_by => [ :standardPrice, :salePrice ],
#     :order_by_order => :desc
#   ) { |s| s.sku.nil? }
#   qry.to_sql # => "select * from skus where skus.sku is null order by
#                    standardPrice, salePrice desc"
# 
# = Query inference operators
# You can compare fields either to simple values, or to other fields in the same
# table.
#   paid_immediately = Invoice.get { |inv|
#     inv.date.equals( inv.paid )
#   }
#   # => "select * from invoices where date = paid"
#
# == Numerical comparisons: +lt+, +lte+, +gte+, +gt+
# +lt+, +lte+, +gte+, and +gt+ stand for "less than", "less than or equal",
# "greater than or equal", and "greater than", respectively.
#   tiny_invoices = Invoice.get { |inv| inv.rate.lte( 25 ) }
#   # => "select * from invoices where rate <= 25"
# These comparators work on fields that contain numbers, dates, and even
# references to other domain objects.
#   for_1st_ten_clients = Invoice.get { |inv|
#     inv.client.lte( 10 )
#   }
#   # => "select * from invoices where client <= 10"
#   client10 = Client[10]
#   for_1st_ten_clients = Invoice.get { |inv|
#     inv.client.lte( client10 )
#   }
#   # => "select * from invoices where client <= 10"
#
# == Equality: +equals+
#   full_week_invs = Invoice.get { |inv| inv.hours.equals( 40 ) }
#   # => "select * from invoices where hours = 40"
# If you're comparing to a domain object you should pass in the object itself.
#   client = Client[99]
#   invoices = Invoice.get { |inv| inv.client.equals( client ) }
#   # => "select * from invoices where client = 99"
# If you're comparing to a boolean value you don't need to use
# <tt>equals( true )</tt>.
#   administrators = User.get { |u| u.administrator.equals( true ) }
#   administrators = User.get { |u| u.administrator } # both forms work
# Matching for +nil+ can use <tt>nil?</tt>
#   no_email = User.get { |u| u.email.nil? }
# 
# == Inclusion: +in+ and <tt>include?</tt>
# Any field can be matched via +in+:
#   first_three_invs = Invoice.get { |inv| inv.pk_id.in( 1, 2, 3 ) }
#   # => "select * from invoices where pk_id in ( 1, 2, 3 )"
# A TextListField can be matched via <tt>include?</tt>
#   aim_users = User.get { |u| u.im_methods.include?( 'aim' ) }
#   # => "select * from users where user.im_methods like 'aim,%' or
#         user.im_methods like '%,aim,%' or user.im_methods like '%,aim' or
#         user.im_methods = 'aim'"
#
# == Text comparison: +like+
#   fname_starts_with_a = User.get { |user| user.fname.like( /^a/ ) }
#   # => "select * from users where fname like 'a%'"
#   fname_ends_with_a = User.get { |user| user.fname.like( /a$/ ) }
#   # => "select * from users where fname like '%a'"
#   fname_contains_a = User.get { |user| user.fname.like( /a/ ) }
#   # => "select * from users where fname like '%a%'"
#   james_or_jones = User.get { |user| user.lname.like( /J..es/ ) }
#   # => "select * from users where lname like 'J__es'"
# Please note that although we're using the Regexp operators here, these aren't
# full-fledged regexps. Only ^, $, and . work for this.
#
# == Compound conditions: <tt>&</tt> and <tt>|</tt>
#   invoices = Invoice.get { |inv|
#     inv.hours.equals( 40 ) & inv.rate.equals( 50 )
#   }
#   # => "select * from invoices where (hours = 40 and rate = 50)"
#   client99 = Client[99]
#   invoices = Invoice.get { |inv|
#     inv.hours.equals( 40 ) | inv.rate.equals( 50 ) |
#       inv.client.equals( client99 )
#   }
#   # => "select * from invoices where (hours = 40 or rate = 50 or client = 99)"
# Note that both compound operators can be nested:
#   invoices = Invoice.get { |inv|
#     inv.hours.equals( 40 ) &
#       ( inv.rate.equals( 50 ) | inv.client.equals( client99 ) )
#   }
#   # => "select * from invoices where (hours = 40 and 
#   #     (rate = 50 or client = 99))"
#
# == Negation: +not+
#   invoices = Invoice.get { |inv| inv.rate.equals( 50 ).not }
#   # => "select * from invoices where rate != 50"
# This can be used directly against boolean and nil comparisons, too.
#   not_administrators = User.get { |u| u.administrator.not }
#   # => "select * from users where administrator != 1"
#   has_email = User.get { |u| u.email.nil?.not }
#   # => "select * from users where email is not null"
#
# = Query caching via subset matching
# Lafcadio caches every query, and optimizes based on a simple subset
# calculation. For example, if you run these statements:
#   User.get { |u| u.lname.equals( 'Smith' ) }
#   User.get { |u| u.lname.equals( 'Smith' ) & u.fname.like( /John/ ) }
#   User.get { |u| u.lname.equals( 'Smith' ) & u.email.like( /hotmail/ ) }
# Lafcadio can tell that the 2nd and 3rd queries are subsets of the first. So
# these three statements will result in one database call, for the first 
# statement: The 2nd and 3rd statements will be handled entirely in Ruby. The 
# result is less database calls with no extra work for the programmer.

require 'delegate'

module Lafcadio
	class Query
		def self.And( *conditions ) #:nodoc:
			CompoundCondition.new( *conditions )
		end
		
		# Infers a query from a block. The first required argument is the domain 
		# class. Other optional arguments should be passed in hash form:
		# [:order_by] An array of fields to order the results by.
		# [:order_by_order] Possible values are :asc or :desc. Defaults to :desc.
		#   qry = Query.infer( User ) { |u| u.lname.equals( 'Hwang' ) }
		#   qry.to_sql # => "select * from users where users.lname = 'Hwang'"
		#   qry = Query.infer(
		#     SKU,
		#     :order_by => [ :standardPrice, :salePrice ],
		#     :order_by_order => :desc
		#   ) { |s| s.sku.nil? }
		#   qry.to_sql # => "select * from skus where skus.sku is null order by
		#                    standardPrice, salePrice desc"
		def self.infer( *args, &action )
			inferrer = Query::Inferrer.new( *args ) { |obj| action.call( obj ) }
			inferrer.execute
		end
		
		def self.Or( *conditions ) #:nodoc:
			conditions << :or
			CompoundCondition.new( *conditions)
		end

		attr_reader :domain_class, :condition, :include, :limit, :order_by
		attr_accessor :order_by_order

		def initialize(domain_class, opts = {} ) #:nodoc:
			@domain_class, @opts = domain_class, opts
			( @condition, @order_by, @limit ) = [ nil, nil, nil ]
			if ( cond = opts[:condition] )
				@condition = cond
			elsif ( pk_id = opts[:pk_id] )
				@condition = Query::Equals.new( :pk_id, pk_id, domain_class )
			end
			if ( @include = opts[:include] )
				@include = [ @include ] unless @include.is_a?( Array )
			end
			@order_by_order = :asc
		end
		
		# Returns a new query representing the condition of the current query and
		# the new inferred query.
		#   qry = Query.infer( User ) { |u| u.lname.equals( 'Hwang' ) }
		#   qry.to_sql # => "select * from users where users.lname = 'Hwang'"
		#   qry = qry.and { |u| u.fname.equals( 'Francis' ) }
		#   qry.to_sql # => "select * from users where (users.lname = 'Hwang' and
		#                    users.fname = 'Francis')"
		def and( &action ); compound( :and, action ); end
		
		def collect( coll ) #:nodoc:
			if @opts[:group_functions] == [:count]
				[ result_row( [coll.size] ) ]
			else
				raise
			end
		end
			
		def compound( comp_type, action ) #:nodoc:
			rquery = Query.infer( @domain_class ) { |dobj| action.call( dobj ) }
			q = Query::CompoundCondition.new(
				@condition, rquery.condition, comp_type
			).query
			[ :order_by, :order_by_order, :limit ].each do |attr|
				q.send( attr.to_s + '=', self.send( attr ) )
			end
			q
		end
		
		def dobj_satisfies?( dobj ) #:nodoc:
			@condition.nil? or @condition.dobj_satisfies?( dobj )
		end

		def eql?( other ) #:nodoc:
			other.is_a?( Query ) && other.to_sql == to_sql
		end

		def fields #:nodoc:
			@opts[:group_functions] == [:count] ? 'count(*)' : '*'
		end

		def hash #:nodoc:
			to_sql.hash
		end
		
		def implies?( other_query ) #:nodoc:
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
		
		def limit=( limit )
			@limit = limit.is_a?( Fixnum ) ? 0..limit-1 : limit
		end
		
		def limit_clause( db ) #:nodoc:
			if @limit
				case db
				when 'Mysql'
					"limit #{ @limit.begin }, #{ @limit.end - @limit.begin + 1 }"
				when 'Pg'
					limit_clause = "limit #{ @limit.end - @limit.begin + 1 }"
					limit_clause += " offset #{ @limit.begin }" if @limit.begin > 0
					limit_clause
				end
			end
		end
		
		def one_pk_id?; @condition and @condition.one_pk_id?; end
		
		# Returns a new query representing the condition of the current query and
		# the new inferred query.
		#   qry = Query.infer( User ) { |u| u.lname.equals( 'Hwang' ) }
		#   qry.to_sql # => "select * from users where users.lname = 'Hwang'"
		#   qry = qry.or { |u| u.fname.equals( 'Francis' ) }
		#   qry.to_sql # => "select * from users where (users.lname = 'Hwang' or
		#                    users.fname = 'Francis')"
		def or( &action ); compound( :or, action ); end
		
		def order_by=( ob )
			@order_by = ( ob.is_a?( Array ) ? ob.map { |f| f.to_s } : ob.to_s ) if ob
		end
		
		def order_clause #:nodoc:
			if @order_by
				field_str = @order_by.map { |f_name|
					@domain_class.field( f_name.to_s ).db_field_name
				}.join( ', ' )
				clause = "order by #{ field_str } "
				clause += @order_by_order == :asc ? 'asc' : 'desc'
				clause
			end
		end
		
		def order_and_limit_collection( objects )
			objects = objects.sort_by { |dobj|
				if order_by.nil?
					dobj.pk_id
				elsif order_by.is_a?( Array )
					order_by.map { |field_name| dobj.send( field_name ) }
				else
					dobj.send order_by
				end
			}
			objects.reverse! if order_by_order == :desc
			objects = objects[limit] if limit
			objects
		end
		
		def result_row( row ) #:nodoc:
			if @opts[:group_functions] == [:count]
				{ :count => row.first }
			else
				raise
			end
		end

		def sql_primary_key_field(domain_class) #:nodoc:
			"#{ domain_class.table_name }.#{ domain_class.sql_primary_key_name }"
		end

		def tables #:nodoc:
			concrete_classes = domain_class.self_and_concrete_superclasses.reverse
			sql = ''
			dclass = nil
			until concrete_classes.empty?
				prev_dclass = dclass
				dclass = concrete_classes.shift
				if sql == ''
					sql = dclass.table_name
				else
					sql += " inner join #{ dclass.table_name } on #{ sql_primary_key_field( prev_dclass ) } = #{ sql_primary_key_field( dclass ) }"
				end
			end
			if @include
				@include.each do |include_sym|
					field = dclass.field include_sym
					included_dclass = field.linked_type
					sql += " left outer join #{ included_dclass.table_name } on #{ dclass.table_name }.#{ field.db_field_name } = #{ sql_primary_key_field( included_dclass ) }"
				end
			end
			sql
		end

		def to_sql( db = 'Mysql' )
			clauses = [ "select #{ fields }", "from #{ tables }" ]
			clauses << where_clause if where_clause
			clauses << order_clause if order_clause
			clauses << limit_clause( db ) if limit_clause( db )
			clauses.join ' '
		end

		def where_clause #:nodoc:
			where_clauses = []
			where_clauses << @condition.to_sql if @condition
			!where_clauses.empty? ? 'where ' + where_clauses.join( ' and ' ) : nil
		end

		class Condition #:nodoc:
			def Condition.search_term_type
				Object
			end

			attr_reader :domain_class

			def initialize(fieldName, searchTerm, domain_class)
				@fieldName, @searchTerm, @domain_class =
						fieldName, searchTerm, domain_class
				unless @searchTerm.is_a?( self.class.search_term_type )
					raise "Incorrect searchTerm type #{ searchTerm.class }"
				end
				if @domain_class and !( @domain_class < DomainObject )
					raise "Incorrect object type #{ @domain_class.to_s }"
				end
			end
			
			def |( other_cond ); Query.Or( self, other_cond ); end
			
			def &( other_cond ); Query.And( self, other_cond ); end
			
			def implies?( other_condition )
				self.eql?( other_condition ) or (
					other_condition.respond_to?( :implied_by? ) and 
							other_condition.implied_by?( self )
				)
			end
			
			def db_field_name; field.db_column; end
			
			def eql?( other_cond )
				other_cond.is_a?( Condition ) and other_cond.to_sql == to_sql
			end
			
			def field
				f = @domain_class.field @fieldName.to_s
				f or raise(
					MissingError,
					"Couldn't find field \"#{ @fieldName }\" in " + @domain_class.name +
							" domain class",
					caller
				)
			end
			
			def not; Query::Not.new( self ); end
			
			def one_pk_id?; self.is_a?( Equals ) and primary_key_field?; end

			def primary_key_field?; 'pk_id' == @fieldName; end
			
			def query; Query.new( @domain_class, :condition => self ); end
			
			def to_condition; self; end
		end

		class Compare < Condition #:nodoc:
			@@comparators = { :lt => '<', :lte => '<=', :gte => '>=', :gt => '>' }

			@@mockComparators = {
				:lt => Proc.new { |d1, d2| d1 < d2 },
				:lte => Proc.new { |d1, d2| d1 <= d2 },
				:gte => Proc.new { |d1, d2| d1 >= d2 },
				:gt => Proc.new { |d1, d2| d1 > d2 }
			}

			def initialize(fieldName, searchTerm, domain_class, compareType)
				super fieldName, searchTerm, domain_class
				@compareType = compareType
			end

			def dobj_satisfies?(anObj)
				value = anObj.send @fieldName
				value = value.pk_id if value.class <= DomainObject
				if value
					@@mockComparators[@compareType].call(value, @searchTerm)
				else
					false
				end
			end

			def to_sql
				if ( field.kind_of?( DomainObjectField ) &&
				     !@searchTerm.respond_to?( :pk_id ) )
					search_val = @searchTerm.to_s
				else
					search_val = field.value_for_sql( @searchTerm ).to_s
				end
				"#{ db_field_name } #{ @@comparators[@compareType] } #{ search_val }"
			end
		end

		class CompoundCondition < Condition #:nodoc:
			def initialize( *args )
				if( [ :and, :or ].include?( args.last ) )
					@compound_type = args.last
					args.pop
				else
					@compound_type = :and
				end
				@conditions = args.map { |arg|
					arg.respond_to?( :to_condition ) ? arg.to_condition : arg
				}
				@domain_class = @conditions[0].domain_class
			end

			def dobj_satisfies?(anObj)
				if @compound_type == :and
					@conditions.inject( true ) { |result, cond|
						result && cond.dobj_satisfies?( anObj )
					}
				else
					@conditions.inject( false ) { |result, cond|
						result || cond.dobj_satisfies?( anObj )
					}
				end
			end

			def implied_by?( other_condition )
				@compound_type == :or && @conditions.any? { |cond|
					cond.implies?( other_condition )
				}
			end
			
			def implies?( other_condition )
				super( other_condition ) or (
					@compound_type == :and and @conditions.any? { |cond|
						cond.implies? other_condition
					}
				) or (
					@compound_type == :or and @conditions.all? { |cond|
						cond.implies? other_condition
					}
				)
			end

			def to_sql
				booleanString = @compound_type == :and ? 'and' : 'or'
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
							if ( classField = self.domain_class.field( fieldName ) )
								ObjectFieldImpostor.new( self, classField )
							else
								msg = "undefined method `" + fieldName +
								      "' for #<DomainObjectImpostor::" +
								      '#{ domain_class.name }' + ">"
								raise( NoMethodError, msg )
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
			def dobj_satisfies?(anObj)
				if @searchTerm.is_a?( ObjectField )
					compare_value = anObj.send @searchTerm.name
				else
					compare_value = @searchTerm
				end
				compare_value == anObj.send( @fieldName )
			end

			def r_val_string
				if @searchTerm.is_a?( ObjectField )
					@searchTerm.db_column
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

			def to_sql
				sql = "#{ db_field_name } "
				sql += ( !@searchTerm.nil? ? "= #{ r_val_string }" : "is null" )
				sql
			end
		end

		class In < Condition #:nodoc:
			def self.search_term_type; Array; end

			def dobj_satisfies?(anObj)
				@searchTerm.include?( anObj.send( @fieldName ) )
			end

			def to_sql
				if field.is_a?( StringField )
					quoted = @searchTerm.map do |str| "'#{ str }'"; end
					end_clause = quoted.join ', '
				else
					end_clause = @searchTerm.join ', '
				end
				"#{ db_field_name } in (#{ end_clause })"
			end
		end
		
		class Include < CompoundCondition #:nodoc:
			def initialize( field_name, search_term, domain_class )
				begin_cond = Like.new(
					field_name, search_term + ',', domain_class, :post_only
				)
				mid_cond = Like.new(
					field_name, ',' + search_term + ',', domain_class
				)
				end_cond = Like.new(
					field_name, ',' + search_term, domain_class, :pre_only
				)
				only_cond = Equals.new( field_name, search_term, domain_class )
				super( begin_cond, mid_cond, end_cond, only_cond, :or )
			end
		end

		class Inferrer #:nodoc:
			def initialize( *args, &action )
				@domain_class = args.first; @action = action
				unless args.size == 1
					h = args.last
					@order_by = h[:order_by]
					@order_by_order = ( h[:order_by_order] or :asc )
					@limit = h[:limit]
				end
			end
			
			def execute
				impostor = DomainObjectImpostor.impostor @domain_class
				condition = @action.call( impostor ).to_condition
				query = Query.new( @domain_class, :condition => condition )
				query.order_by = @order_by
				query.order_by_order = @order_by_order
				query.limit = @limit
				query
			end
		end
		
		class Like < Condition #:nodoc:
			def initialize(
				fieldName, searchTerm, domain_class, matchType = :pre_and_post
			)
				if searchTerm.is_a? Regexp
					searchTerm = process_regexp searchTerm
				else
					@matchType = matchType
				end
				super fieldName, searchTerm, domain_class
			end
			
			def dobj_satisfies?(anObj)
				value = anObj.send @fieldName
				value = value.pk_id.to_s if value.respond_to?( :pk_id )
				if value.is_a?( Array )
					value.include? @searchTerm
				else
					!regexp.match( value ).nil?
				end
			end
			
			def process_regexp( searchTerm )
				if searchTerm.source =~ /^\^(.*)/
					@matchType = :post_only
					$1
				elsif searchTerm.source =~ /(.*)\$$/
					@matchType = :pre_only
					$1
				else
					@matchType = :pre_and_post
					searchTerm.source
				end
			end

			def regexp
				if @matchType == :pre_and_post
					Regexp.new( @searchTerm, Regexp::IGNORECASE )
				elsif @matchType == :pre_only
					Regexp.new( @searchTerm.to_s + "$", Regexp::IGNORECASE )
				elsif @matchType == :post_only
					Regexp.new( "^" + @searchTerm, Regexp::IGNORECASE )
				end
			end

			def to_sql
				withWildcards = @searchTerm.clone
				if @matchType == :pre_and_post
					withWildcards = "%" + withWildcards + "%"
				elsif @matchType == :pre_only
					withWildcards = "%" + withWildcards
				elsif @matchType == :post_only
					withWildcards += "%"
				end
				withWildcards.gsub!( /(\\?\.)/ ) { |m| m.size == 1 ? "_" : "." }
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
					a_value = d_obj.send @field_name
					( max.nil? || a_value > max ) ? a_value : max
				}
				[ result_row( [max] ) ]
			end
		
			def fields
				"max(#{ @domain_class.field( @field_name ).db_field_name })"
			end
			
			def result_row( row ); { :max => row.first }; end
		end

		class Not < Condition #:nodoc:
			def initialize(unCondition)
				@unCondition = unCondition
			end

			def dobj_satisfies?(obj)
				!@unCondition.dobj_satisfies?(obj)
			end
			
			def domain_class; @unCondition.domain_class; end

			def to_sql
				"!(#{ @unCondition.to_sql })"
			end
		end

		class ObjectFieldImpostor #:nodoc:
			def self.comparators
				{ 'lt' => :lt, 'lte' => :lte, 'gte' => :gte, 'gt' => :gt }
			end
			
			attr_reader :class_field
		
			def initialize( domainObjectImpostor, class_field )
				@domainObjectImpostor = domainObjectImpostor
				@class_field = class_field
				@field_name = class_field.name
			end
			
			def &( condition ); Query.And( to_condition, condition ); end

			def |( condition ); Query.Or( to_condition, condition ); end
			
			def method_missing( methId, *args )
				methodName = methId.id2name
				if self.class.comparators.keys.include?( methodName )
					compare_condition( methodName, *args )
				else
					super
				end
			end
			
			def compare_condition( compareStr, searchTerm)
				compareVal = ObjectFieldImpostor.comparators[compareStr]
				Compare.new( @field_name, searchTerm, domain_class, compareVal )
			end
			
			def domain_class; @domainObjectImpostor.domain_class; end
			
			def equals( searchTerm )
				Equals.new(
					@field_name, field_or_field_name( searchTerm ), domain_class
				)
			end
			
			def field_or_field_name( search_term )
				if search_term.is_a? ObjectFieldImpostor
					search_term.class_field
				else
					search_term
				end
			end
			
			def include?( search_term )
				if @class_field.is_a?( TextListField )
					Include.new( @field_name, search_term, domain_class )
				else
					raise ArgumentError
				end
			end
			
			def like( regexp )
				if regexp.is_a?( Regexp )
					Query::Like.new( @field_name, regexp, domain_class )
				else
					raise(
						ArgumentError, "#{ @field_name }#like needs to receive a Regexp",
						caller
					)
				end
			end
			
			def in( *searchTerms )
				Query::In.new( @field_name, searchTerms, domain_class )
			end
			
			def nil?; equals( nil ); end
			
			def to_condition
				if @class_field.instance_of?( BooleanField )
					Query::Equals.new( @field_name, true, domain_class )
				else
					raise
				end
			end
			
			def not; to_condition.not; end
		end
	end
end