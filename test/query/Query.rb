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

	def testOneObjId
		query = Query.new SKU, 199
    assert_equal 'select * from skus where objId = 199', query.toSql
	end

	def testByCondition
		client = Client.new({ 'objId' => 13 })
		condition = Query::Equals.new('client', client, Invoice)
		query = Query.new Invoice, condition
		assert_equal 'select * from invoices where client = 13', query.toSql
	end

	def testGetSubsetWithCondition
		condition = Query::In.new('client', [ 1, 2, 3 ], Invoice)
		query = Query.new Invoice, condition
		assert_equal 'select * from invoices where client in (1, 2, 3)', query.toSql
	end

	def testTableJoinsForInheritance
		query = Query.new InternalClient, 1
		assert_equal 'select * from clients, internalClients ' +
				'where clients.objId = internalClients.objId and ' +
				'objId = 1', query.toSql
		condition = Query::Equals.new('billingType', 'whatever', InternalClient)
		query2 = Query.new InternalClient, condition
		assert_equal "select * from clients, internalClients " +
				"where clients.objId = internalClients.objId and " +
				"billingType = 'whatever'", query2.toSql
	end

	def testOrderBy
		query = Query.new Client
		query.orderBy = 'name'
		query.orderByOrder = Query::DESC
		assert_equal 'select * from clients order by name desc', query.toSql
	end

	def testLimit
		query = Query.new Client
		query.limit =(10..29)
		assert_equal 'select * from clients limit 10, 29', query.toSql
	end
end