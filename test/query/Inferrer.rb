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
end