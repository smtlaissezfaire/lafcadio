require 'date'
require 'lafcadio/query'
require 'lafcadio/test'
require '../test/mock/domain'

class TestCompare < LafcadioTestCase
	def testComparators
		comparators = {
			Query::Compare::LESS_THAN => '<',
			Query::Compare::LESS_THAN_OR_EQUAL => '<=',
			Query::Compare::GREATER_THAN_OR_EQUAL => '>=',
			Query::Compare::GREATER_THAN => '>'
		}
		comparators.each { |compareType, comparisonSymbol|
			dc = Query::Compare.new('date', Date.new(2003, 1, 1), Invoice,
					compareType)
			assert_equal( "invoices.date #{ comparisonSymbol } '2003-01-01'",
			              dc.to_sql )
		}
	end
	
	def testDbFieldName
		compare = Query::Compare.new( 'text1', 'foobar', XmlSku,
		                              Query::Compare::LESS_THAN )
		assert_equal( "some_other_table.text_one < 'foobar'", compare.to_sql )
	end

	def testFieldBelongingToSuperclass
		condition = Query::Compare.new('standard_rate', 10, InternalClient,
				Query::Compare::LESS_THAN)
		assert_equal( 'clients.standard_rate < 10', condition.to_sql )
	end

	def test_handles_dobj_that_doesnt_exist
		condition = Query::Compare.new( 'client',
		                                DomainObjectProxy.new( Client, 10 ),
																		Invoice, Query::Compare::LESS_THAN )
		assert_equal( 'invoices.client < 10', condition.to_sql )
		assert_equal( 0, @mockObjectStore.get_subset( condition ).size )
		condition2 = Query::Compare.new( 'client', 10, Invoice,
		                                 Query::Compare::LESS_THAN )
		assert_equal( 'invoices.client < 10', condition2.to_sql )
		assert_equal( 0, @mockObjectStore.get_subset( condition2 ).size )		
	end
	
	def testLessThan
		condition = Query::Compare.new(
				User.sql_primary_key_name, 10, User, Query::Compare::LESS_THAN)
		assert_equal( 'users.pk_id < 10', condition.to_sql )
	end

	def testMockComparatorAndNilValue
		invoice = Invoice.getTestInvoice
		invoice.date = nil
		dc = Query::Compare.new(
				'date', Date.today, Invoice, Query::Compare::LESS_THAN)
		assert !dc.object_meets(invoice)
	end

	def testMockComparators
		date1 = Date.new(2001, 1, 1)
		date2 = Date.new(2002, 1, 1)
		date3 = Date.new(2003, 1, 1)
		invoice = Invoice.getTestInvoice
		invoice1 = invoice.clone
		invoice1.date = date1
		invoice2 = invoice.clone
		invoice2.date = date2
		invoice3 = invoice.clone
		invoice3.date = date3
		dc1 = Query::Compare.new(
				'date', date2, Invoice, Query::Compare::LESS_THAN)
		assert dc1.object_meets(invoice1)
		assert !dc1.object_meets(invoice2)
		assert !dc1.object_meets(invoice3)
		dc2 = Query::Compare.new(
				'date', date2, Invoice,
				Query::Compare::LESS_THAN_OR_EQUAL)
		assert dc2.object_meets(invoice1)
		assert dc2.object_meets(invoice2)
		assert !dc2.object_meets(invoice3)
		dc3 = Query::Compare.new(
				'date', date2, Invoice,
				Query::Compare::GREATER_THAN)
		assert !dc3.object_meets(invoice1)
		assert !dc3.object_meets(invoice2)
		assert dc3.object_meets(invoice3)
		dc4 = Query::Compare.new(
				'date', date2, Invoice,
				Query::Compare::GREATER_THAN_OR_EQUAL)
		assert !dc4.object_meets(invoice1)
		assert dc4.object_meets(invoice2)
		assert dc4.object_meets(invoice3)
	end

	def testNumericalSearchingOfaLinkField
		condition = Query::Compare.new('client', 10, Invoice,
				Query::Compare::LESS_THAN)
		assert_equal( 'invoices.client < 10', condition.to_sql )
	end
end

class TestCompoundCondition < LafcadioTestCase
	def testCompareAndBooleanEquals		
		pastExpDate = Query::Compare.new('date',
				Date.new(2003, 1, 1), Invoice,
				Query::Compare::GREATER_THAN_OR_EQUAL)
		notExpiredYet = Query::Equals.new('hours', 10, Invoice)
		condition = Query::CompoundCondition.new(pastExpDate, notExpiredYet)
		assert_equal( "(invoices.date >= '2003-01-01' and invoices.hours = 10)",
		              condition.to_sql )
		assert_equal Invoice, condition.domain_class
	end

	def testMoreThanTwoConditions
		pastExpDate = Query::Compare.new('date',
				Date.new(2003, 1, 1), Invoice,
				Query::Compare::GREATER_THAN_OR_EQUAL)
		notExpiredYet = Query::Equals.new('rate', 10, Invoice)
		notComplementary = Query::Equals.new(
				'hours', 10, Invoice)
		condition = Query::CompoundCondition.new(
				pastExpDate, notExpiredYet, notComplementary)
		assert_equal( "(invoices.date >= '2003-01-01' and invoices.rate = 10 and " +
		              "invoices.hours = 10)",
		              condition.to_sql )
		invoice = Invoice.new({ 'pk_id' => 1, 'date' => Date.new(2003, 1, 1),
				'rate' => 10, 'hours' => 10 })
		assert condition.object_meets(invoice)
		invoice.hours = 10.5
		assert !condition.object_meets(invoice)
	end

	def testOr
		email = Query::Equals.new('email', 'test@test.com', User)
		fname = Query::Equals.new('firstNames', 'John', User)
		user = User.getTestUser
		assert email.object_meets(user)
		assert !fname.object_meets(user)
		compound = Query::CompoundCondition.new(email, fname,
				Query::CompoundCondition::OR)
		assert_equal( "(users.email = 'test@test.com' or " +
		              "users.firstNames = 'John')",
		              compound.to_sql )
		assert compound.object_meets(user)
	end
end

class TestCondition < LafcadioTestCase
	def testRaisesExceptionIfInitHasWrongArguments
		cond = Query::Condition.new( 'att name', 'name', Attribute )
		begin
			cond.get_field
			fail "needs to raise MissingError"
		rescue MissingError
			errStr = "Couldn't find field \"att name\" in Attribute domain class"
			assert_equal( $!.to_s, errStr )
		end
	end
end

class TestEquals < LafcadioTestCase
	def testBooleanField
		equals = Query::Equals.new( 'administrator', false, User )
		assert_equal( 'users.administrator = 0', equals.to_sql )
	end

	def test_compare_to_other_field
		email_field = User.get_field( 'email' )
		equals = Query::Equals.new( 'firstNames', email_field, User )
		assert_equal( 'users.firstNames = users.email', equals.to_sql )
		odd_user = User.new( 'email' => 'foobar', 'firstNames' => 'foobar' )
		assert( equals.object_meets( odd_user ) )
	end

	def testDbFieldName
		equals = Query::Equals.new( 'text1', 'foobar', XmlSku )
		assert_equal( "some_other_table.text_one = 'foobar'", equals.to_sql )
	end

	def test_different_pk_name
		equals1 = Query::Equals.new( 'pk_id', 123, XmlSku )
		assert_equal( 'some_other_table.some_other_id = 123', equals1.to_sql )
	end

	def testEqualsByFieldType
		equals = Query::Equals.new('email', 'john.doe@email.com', User)
		assert_equal( "users.email = 'john.doe@email.com'", equals.to_sql )
		equals2 = Query::Equals.new('date', Date.new(2003, 1, 1), Invoice)
		assert_equal( "invoices.date = '2003-01-01'", equals2.to_sql )
	end

	def testNullClause
		equals = Query::Equals.new('date', nil, Invoice)
		assert_equal( 'invoices.date is null', equals.to_sql )
	end

	def testPkId
		equals = Query::Equals.new('pk_id', 123, Client)
		assert_equal( 'clients.pk_id = 123', equals.to_sql )
	end

	def testSubclass
		clientCondition = Query::Equals.new('name', 'client 1', InternalClient)
		assert_equal( "clients.name = 'client 1'", clientCondition.to_sql )
	end
end

class TestQueryInferrer < LafcadioTestCase
	def assert_infer_match( desiredSql, domain_class, &action )
		inferrer = Query::Inferrer.new( domain_class ) { |obj| action.call( obj ) }
		assert_equal( desiredSql, inferrer.execute.to_sql )
	end

	def testCompare
		date = Date.new( 2003, 1, 1 )
		method_operator_hash = { 'lt' => '<', 'lte' => '<=', 'gte' => '>=',
		                         'gt' => '>' }
		method_operator_hash.each { |method, operator|
			desired_sql = "select * from invoices where invoices.date " +
			              "#{ operator } '2003-01-01'"
			assert_infer_match( desired_sql, Invoice ) { |inv|
				inv.date.send( method, date )
			}
		}
	end

	def testCompareFieldBelongingToSuperclass
		desiredSql = "select * from clients, internalClients " +
		             "where clients.pk_id = internalClients.pk_id and " +
                 "clients.standard_rate < 10"
    assert_infer_match( desiredSql, InternalClient ) { |intc|
			intc.standard_rate.lt( 10 )
		}
	end

	def testCompareToLinkField
		desiredSql = "select * from invoices where invoices.client < 10"
		assert_infer_match( desiredSql, Invoice ) { |inv| inv.client.lt( 10 ) }
	end
	
	def testCompound
		desiredSql = "select * from invoices " +
		             "where (invoices.date >= '2003-01-01' and invoices.hours = 10)"
		date = Date.new( 2003, 1, 1 )
		assert_infer_match( desiredSql, Invoice ) { |inv|
			Query.And( inv.date.gte( date ), inv.hours.equals( 10 ) )
		}
	end
	
	def testCompoundThree
		desiredSql = "select * from invoices " +
		             "where (invoices.date >= '2003-01-01' and " +
		             "invoices.rate = 10 and invoices.hours = 10)"
		date = Date.new( 2003, 1, 1 )
		assert_infer_match( desiredSql, Invoice ) { |inv|
			Query.And( inv.date.gte( date ), inv.rate.equals( 10 ),
								 inv.hours.equals( 10 ) )
		}
	end

	def testEquals
		desiredSql = "select * from invoices where invoices.hours = 10"
		assert_infer_match( desiredSql, Invoice ) { |inv| inv.hours.equals( 10 ) }
		desired_sql2 = 'select * from inventoryLineItemOptions ' +
		               'where inventoryLineItemOptions.optionId = 1'
		assert_infer_match( desired_sql2, InventoryLineItemOption ) { |ilio|
			ilio.option.equals( TestOption.storedTestOption )
		}
	end

	def test_field_compare
		desired_sql = 'select * from invoices where invoices.date = invoices.paid'
		assert_infer_match( desired_sql, Invoice ) { |inv|
			inv.date.equals( inv.paid )
		}
		desired_sql2 = 'select * from some_other_table ' +
		               'where some_other_table.text_one = some_other_table.text2'
		assert_infer_match( desired_sql2, XmlSku ) { |xml_sku|
			xml_sku.text1.equals( xml_sku.text2 )
		}
		desired_sql3 = 'select * from invoices where invoices.pk_id > 10'
		assert_infer_match( desired_sql3, Invoice ) { |inv| inv.pk_id.gt( 10 ) }
	end

	def test_implied_boolean_eval
		desired_sql1 = 'select * from users where users.administrator = 1'
		assert_infer_match( desired_sql1, User ) { |user| user.administrator }
		desired_sql2 = 'select * from users where !(users.administrator = 1)'
		assert_infer_match( desired_sql2, User ) { |user| user.administrator.not }
		desired_sql3 =
			"select * from users " +
			"where (!(users.administrator = 1) and users.email = 'test@test.com')"
		assert_infer_match( desired_sql3, User ) { |user|
			Query.And( user.administrator.not, user.email.equals( 'test@test.com' ) )
		}
	end

	def testIn
		desiredSql = "select * from invoices where invoices.pk_id in (1, 2, 3)"
		assert_infer_match( desiredSql, Invoice ) { |inv|
			inv.pk_id.in( 1, 2, 3 )
		}
	end

	def test_include?
		desired_sql =
			"select * from some_other_table where (" +
			"some_other_table.text_list1 like '123,%' or " +
			"some_other_table.text_list1 like '%,123,%' or " +
			"some_other_table.text_list1 like '%,123' or " +
			"some_other_table.text_list1 = '123')"
		assert_infer_match( desired_sql, XmlSku ) { |xml_sku|
			xml_sku.textList1.include?( '123' )
		}
		assert_raise( ArgumentError ) {
			Query.infer( Client ) { |cli| cli.name.include?( 'a' ) }
		}
	end

	def testLike
		desiredSql1 = "select * from users where users.email like '%hotmail%'"
		assert_infer_match( desiredSql1, User ) { |user|
			user.email.like( /hotmail/ )
		}
		desiredSql2 = "select * from users where users.email like 'hotmail%'"
		assert_infer_match( desiredSql2, User ) { |user|
			user.email.like( /^hotmail/ )
		}
		desiredSql3 = "select * from users where users.email like '%hotmail'"
		assert_infer_match( desiredSql3, User ) { |user|
			user.email.like( /hotmail$/ )
		}
		assert_raise( ArgumentError ) {
			inferrer = Query::Inferrer.new( User ) { |user|
				user.email.like( 'hotmail' )
			}
			inferrer.execute
		}
	end

	def testLink
		aClient = Client.storedTestClient
		desiredSql = "select * from invoices where invoices.client = 1"
		assert_infer_match( desiredSql, Invoice ) { |inv|
			inv.client.equals( aClient )
		}
	end

	def testNot
		desired_sql = "select * from invoices where !(invoices.hours = 10)"
		assert_infer_match( desired_sql, Invoice ) { |inv|
			inv.hours.equals( 10 ).not
		}
	end

	def testOr
		desiredSql = "select * from users " +
		             "where (users.email = 'test@test.com' or " +
		             "users.firstNames = 'John')"
		assert_infer_match( desiredSql, User ) { |u|
			Query.Or( u.email.equals( 'test@test.com' ),
			          u.firstNames.equals( 'John' ) )
		}
	end
end

class TestLike < LafcadioTestCase
	def setup
		super
		@like1 = Query::Like.new('client', '606', Invoice)
		@like2 = Query::Like.new('client', '606', Invoice,
				Query::Like::PRE_ONLY)
		@like3 = Query::Like.new('client', '606', Invoice,
				Query::Like::POST_ONLY)
	end

	def testDbFieldName
		condition = Query::Like.new( 'text1', 'foobar', XmlSku )
		assert_equal( "some_other_table.text_one like '%foobar%'", condition.to_sql )
	end

	def testFieldBelongingToSuperclass
		condition = Query::Like.new('name', 'client name', InternalClient)
		assert_equal( "clients.name like '%client name%'", condition.to_sql )
	end

	def testObjectMeets
		like4 = Query::Like.new('client', '1', Invoice)
		client212 = Client.new({ 'pk_id' => 212 })
		invoiceWith212 = Invoice.new({ 'client' => client212 })
		assert like4.object_meets(invoiceWith212)
		client234 = Client.new({ 'pk_id' => 234 })
		invoiceWith234 = Invoice.new({ 'client' => client234 })
		assert !like4.object_meets(invoiceWith234)
	end

	def testToSql
		assert_equal( "invoices.client like '%606%'", @like1.to_sql )
		assert_equal( "invoices.client like '%606'", @like2.to_sql )
		assert_equal( "invoices.client like '606%'", @like3.to_sql )
	end
end

class TestQuery < LafcadioTestCase
	def testToSql
		query = Query::Max.new(Client)
		assert_equal 'select max(pk_id) from clients', query.to_sql
		query2 = Query::Max.new( Invoice, 'rate' )
		assert_equal( 'select max(rate) from invoices', query2.to_sql )
		query3 = Query::Max.new( XmlSku )
		assert_equal( 'select max(some_other_id) from some_other_table',
		              query3.to_sql )
	end
end

class TestNot < LafcadioTestCase
	def setup
		super
		@not = Query::Not.new(
				Query::Equals.new('email', 'test@test.com', User))
	end
	
	def test_domain_class; assert_equal( User, @not.domain_class ); end

	def testObjectsMeets
		user = User.getTestUser
		assert !@not.object_meets(user)
		user2 = User.new({ 'email' => 'jane.doe@email.com' })
		assert @not.object_meets(user2)
	end

	def testToSql
		assert_equal "!(users.email = 'test@test.com')", @not.to_sql
	end
end

class TestQuery < LafcadioTestCase
	def testByCondition
		client = Client.new({ 'pk_id' => 13 })
		condition = Query::Equals.new('client', client, Invoice)
		query = Query.new Invoice, condition
		assert_equal( 'select * from invoices where invoices.client = 13',
		              query.to_sql )
	end

	def testGetAll
		query = Query.new Domain::LineItem
		assert_equal "select * from lineItems", query.to_sql
	end

	def testGetSubsetWithCondition
		condition = Query::In.new('client', [ 1, 2, 3 ], Invoice)
		query = Query.new Invoice, condition
		assert_equal( 'select * from invoices where invoices.client in (1, 2, 3)',
		              query.to_sql )
	end

	def test_infer
		query = Query.infer( Invoice ) { |inv| inv.rate.equals( 75 ) }
		assert_equal( Query, query.class )
		assert_equal( 'select * from invoices where invoices.rate = 75',
		              query.to_sql )
		query = query.and { |inv| inv.date.gt( Date.new( 2004, 1, 1 ) ) }
		assert_equal(
			'select * from invoices where (invoices.rate = 75 and ' +
					"invoices.date > '2004-01-01')",
			query.to_sql
		)
		query = query.or { |inv| inv.hours.lte( 10 ) }
		assert_equal(
			'select * from invoices where ((invoices.rate = 75 and ' +
					"invoices.date > '2004-01-01') or invoices.hours <= 10)",
			query.to_sql
		)
	end

	def testLimit
		query = Query.new Client
		query.limit = 0..9
		assert_equal 'select * from clients limit 0, 10', query.to_sql
		query2 = Query.new Client
		query2.limit = 10..19
		assert_equal 'select * from clients limit 10, 10', query2.to_sql
	end

	def testOnePkId
		query = Query.new SKU, 199
    assert_equal( 'select * from skus where skus.pk_id = 199', query.to_sql )
		query2 = Query.new( XmlSku, 199 )
		assert_equal(
			'select * from some_other_table ' +
					'where some_other_table.some_other_id = 199',
			query2.to_sql
		)
	end

	def testOrderBy
		query = Query.new Client
		query.order_by = 'name'
		query.order_by_order = Query::DESC
		assert_equal 'select * from clients order by name desc', query.to_sql
	end

	def testTableJoinsForInheritance
		query = Query.new InternalClient, 1
		assert_equal 'select * from clients, internalClients ' +
				'where clients.pk_id = internalClients.pk_id and ' +
				'internalClients.pk_id = 1', query.to_sql
		condition = Query::Equals.new('billingType', 'whatever', InternalClient)
		query2 = Query.new InternalClient, condition
		assert_equal "select * from clients, internalClients " +
				"where clients.pk_id = internalClients.pk_id and " +
				"internalClients.billingType = 'whatever'", query2.to_sql
	end
end
