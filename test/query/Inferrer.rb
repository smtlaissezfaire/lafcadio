require 'lafcadio/query'
require 'lafcadio/test'
require 'test/mock/domain/Invoice'
require 'test/mock/domain/InternalClient'

class TestQueryInferrer < LafcadioTestCase
	def assert_infer_match( desiredSql, domainClass, &action )
		inferrer = Query::Inferrer.new( domainClass ) { |obj| action.call( obj ) }
		assert_equal( desiredSql, inferrer.execute.toSql )
	end

	def testCompare
		date = Date.new( 2003, 1, 1 )
		%w( < <= >= > ).each { |compareSymbol|
			desiredSql = "select * from invoices where date #{ compareSymbol } " +
			             "'2003-01-01'"
			blockStr = "inv.date #{ compareSymbol } date "
			assert_infer_match( desiredSql, Invoice ) { |inv| eval blockStr }
		}
	end

	def testCompareToLinkField
		desiredSql = "select * from invoices where client < 10"
		assert_infer_match( desiredSql, Invoice ) { |inv| inv.client < 10 }
	end
	
	def testCompareFieldBelongingToSuperclass
		desiredSql = "select * from clients, internalClients " +
		             "where clients.objId = internalClients.objId and " +
                 "standard_rate < 10"
    assert_infer_match( desiredSql, InternalClient ) { |intc|
			intc.standard_rate < 10
		}
	end
	
	def testCompound
		desiredSql = "select * from invoices " +
		             "where (date >= '2003-01-01' and hours = 10)"
		date = Date.new( 2003, 1, 1 )
		assert_infer_match( desiredSql, Invoice ) { |inv|
			(inv.date >= date) & (inv.hours == 10)
		}
	end
	
	def testCompoundThree
		desiredSql = "select * from invoices " +
		             "where ((date >= '2003-01-01' and rate = 10) and hours = 10)"
		date = Date.new( 2003, 1, 1 )
		assert_infer_match( desiredSql, Invoice ) { |inv|
			(inv.date >= date) & (inv.rate == 10) & (inv.hours == 10)
		}
	end
	
	def testOr
		desiredSql = "select * from users " +
		             "where (email = 'test@test.com' or firstNames = 'John')"
		assert_infer_match( desiredSql, User ) { |u|
			(u.email == 'test@test.com') | (u.firstNames == 'John')
		}
	end
	
	def testEquals
		desiredSql = "select * from invoices where hours = 10"
		assert_infer_match( desiredSql, Invoice ) { |inv| inv.hours == 10 }
	end
	
	def testIn
		desiredSql = "select * from invoices where objId in (1, 2, 3)"
		assert_infer_match( desiredSql, Invoice ) { |inv|
			inv.in( 'objId', [ 1, 2, 3 ] )
		}
	end
end