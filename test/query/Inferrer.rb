require 'lafcadio/query'
require 'lafcadio/test'
require 'test/mock/domain/Invoice'
require 'test/mock/domain/InternalClient'
require 'test/mock/domain/Client'

class TestQueryInferrer < LafcadioTestCase
	def assert_infer_match( desiredSql, domainClass, &action )
		inferrer = Query::Inferrer.new( domainClass ) { |obj| action.call( obj ) }
		assert_equal( desiredSql, inferrer.execute.toSql )
	end

	def testCompare
		date = Date.new( 2003, 1, 1 )
		method_operator_hash = { 'lt' => '<', 'lte' => '<=', 'gte' => '>=',
		                         'gt' => '>' }
		method_operator_hash.each { |method, operator|
			desired_sql = "select * from invoices where date #{ operator } " +
			              "'2003-01-01'"
			assert_infer_match( desired_sql, Invoice ) { |inv|
				inv.date.send( method, date )
			}
		}
	end

	def testCompareToLinkField
		desiredSql = "select * from invoices where client < 10"
		assert_infer_match( desiredSql, Invoice ) { |inv| inv.client.lt( 10 ) }
	end
	
	def testCompareFieldBelongingToSuperclass
		desiredSql = "select * from clients, internalClients " +
		             "where clients.objId = internalClients.objId and " +
                 "standard_rate < 10"
    assert_infer_match( desiredSql, InternalClient ) { |intc|
			intc.standard_rate.lt( 10 )
		}
	end
	
	def testCompound
		desiredSql = "select * from invoices " +
		             "where (date >= '2003-01-01' and hours = 10)"
		date = Date.new( 2003, 1, 1 )
		assert_infer_match( desiredSql, Invoice ) { |inv|
			Query.And( inv.date.gte( date ), inv.hours.equals( 10 ) )
		}
	end
	
	def testCompoundThree
		desiredSql = "select * from invoices " +
		             "where (date >= '2003-01-01' and rate = 10 and hours = 10)"
		date = Date.new( 2003, 1, 1 )
		assert_infer_match( desiredSql, Invoice ) { |inv|
			Query.And( inv.date.gte( date ), inv.rate.equals( 10 ),
								 inv.hours.equals( 10 ) )
		}
	end

	def testOr
		desiredSql = "select * from users " +
		             "where (email = 'test@test.com' or firstNames = 'John')"
		assert_infer_match( desiredSql, User ) { |u|
			Query.Or( u.email.equals( 'test@test.com' ),
			          u.firstNames.equals( 'John' ) )
		}
	end
	
	def testEquals
		desiredSql = "select * from invoices where hours = 10"
		assert_infer_match( desiredSql, Invoice ) { |inv| inv.hours.equals( 10 ) }
	end
	
	def testIn
		desiredSql = "select * from invoices where objId in (1, 2, 3)"
		assert_infer_match( desiredSql, Invoice ) { |inv|
			inv.objId.in( 1, 2, 3 )
		}
	end
	
	def testLike	
		desiredSql1 = "select * from users where email like '%hotmail%'"
		assert_infer_match( desiredSql1, User ) { |user|
			user.email.like( /hotmail/ )
		}
		desiredSql2 = "select * from users where email like 'hotmail%'"
		assert_infer_match( desiredSql2, User ) { |user|
			user.email.like( /^hotmail/ )
		}
		desiredSql3 = "select * from users where email like '%hotmail'"
		assert_infer_match( desiredSql3, User ) { |user|
			user.email.like( /hotmail$/ )
		}
	end
	
	def testLink
		aClient = Client.storedTestClient
		desiredSql = "select * from invoices where client = 1"
		assert_infer_match( desiredSql, Invoice ) { |inv|
			inv.client.equals( aClient )
		}
	end

	def testNot
		desired_sql = "select * from invoices where !(hours = 10)"
		assert_infer_match( desired_sql, Invoice ) { |inv|
			inv.hours.equals( 10 ).not
		}
	end
end