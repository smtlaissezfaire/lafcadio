require 'lafcadio/test/LafcadioTestCase'
require '../test/mock/domain/LineItem'
require '../test/mock/domain/SKU'
require '../test/mock/domain/User'
require '../test/mock/domain/InternalClient'
require 'lafcadio/query/In'

class TestQuery < LafcadioTestCase
	def testGetAll
		query = Query.new Domain::LineItem
		assert_equal "select * from lineItems", query.toSql
	end

	def testOnePkId
		query = Query.new SKU, 199
    assert_equal( 'select * from skus where skus.pkId = 199', query.toSql )
	end

	def testByCondition
		client = Client.new({ 'pkId' => 13 })
		condition = Query::Equals.new('client', client, Invoice)
		query = Query.new Invoice, condition
		assert_equal( 'select * from invoices where invoices.client = 13',
		              query.toSql )
	end

	def testGetSubsetWithCondition
		condition = Query::In.new('client', [ 1, 2, 3 ], Invoice)
		query = Query.new Invoice, condition
		assert_equal( 'select * from invoices where invoices.client in (1, 2, 3)',
		              query.toSql )
	end

	def testTableJoinsForInheritance
		query = Query.new InternalClient, 1
		assert_equal 'select * from clients, internalClients ' +
				'where clients.pkId = internalClients.pkId and ' +
				'internalClients.pkId = 1', query.toSql
		condition = Query::Equals.new('billingType', 'whatever', InternalClient)
		query2 = Query.new InternalClient, condition
		assert_equal "select * from clients, internalClients " +
				"where clients.pkId = internalClients.pkId and " +
				"internalClients.billingType = 'whatever'", query2.toSql
	end

	def testOrderBy
		query = Query.new Client
		query.orderBy = 'name'
		query.orderByOrder = Query::DESC
		assert_equal 'select * from clients order by name desc', query.toSql
	end

	def testLimit
		query = Query.new Client
		query.limit = 0..9
		assert_equal 'select * from clients limit 0, 10', query.toSql
		query2 = Query.new Client
		query2.limit = 10..19
		assert_equal 'select * from clients limit 10, 10', query2.toSql
	end
end