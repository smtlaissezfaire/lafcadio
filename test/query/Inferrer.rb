require 'lafcadio/query'
require 'lafcadio/test'
require '../test/mock/domain'

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

	def testCompareToLinkField
		desiredSql = "select * from invoices where invoices.client < 10"
		assert_infer_match( desiredSql, Invoice ) { |inv| inv.client.lt( 10 ) }
	end
	
	def testCompareFieldBelongingToSuperclass
		desiredSql = "select * from clients, internalClients " +
		             "where clients.pk_id = internalClients.pk_id and " +
                 "clients.standard_rate < 10"
    assert_infer_match( desiredSql, InternalClient ) { |intc|
			intc.standard_rate.lt( 10 )
		}
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

	def testOr
		desiredSql = "select * from users " +
		             "where (users.email = 'test@test.com' or " +
		             "users.firstNames = 'John')"
		assert_infer_match( desiredSql, User ) { |u|
			Query.Or( u.email.equals( 'test@test.com' ),
			          u.firstNames.equals( 'John' ) )
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
end
