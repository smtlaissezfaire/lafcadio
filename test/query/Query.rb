require 'lafcadio/test'
require '../test/mock/domain/LineItem'
require '../test/mock/domain/SKU'
require '../test/mock/domain/User'
require '../test/mock/domain/InternalClient'
require 'lafcadio/query'

class TestQuery < LafcadioTestCase
	def testGetAll
		query = Query.new Domain::LineItem
		assert_equal "select * from lineItems", query.to_sql
	end

	def testOnePkId
		query = Query.new SKU, 199
    assert_equal( 'select * from skus where skus.pk_id = 199', query.to_sql )
	end

	def testByCondition
		client = Client.new({ 'pk_id' => 13 })
		condition = Query::Equals.new('client', client, Invoice)
		query = Query.new Invoice, condition
		assert_equal( 'select * from invoices where invoices.client = 13',
		              query.to_sql )
	end

	def testGetSubsetWithCondition
		condition = Query::In.new('client', [ 1, 2, 3 ], Invoice)
		query = Query.new Invoice, condition
		assert_equal( 'select * from invoices where invoices.client in (1, 2, 3)',
		              query.to_sql )
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

	def testOrderBy
		query = Query.new Client
		query.order_by = 'name'
		query.order_byOrder = Query::DESC
		assert_equal 'select * from clients order by name desc', query.to_sql
	end

	def testLimit
		query = Query.new Client
		query.limit = 0..9
		assert_equal 'select * from clients limit 0, 10', query.to_sql
		query2 = Query.new Client
		query2.limit = 10..19
		assert_equal 'select * from clients limit 10, 10', query2.to_sql
	end
end