require 'lafcadio/test/LafcadioTestCase'
require '../test/mock/domain/Client'
require 'lafcadio/query/Max'

class TestQuery < LafcadioTestCase
	def testToSql
		query = Query::Max.new(Client)
		assert_equal 'select max(pkId) from clients', query.toSql
		query2 = Query::Max.new( Invoice, 'rate' )
		assert_equal( 'select max(rate) from invoices', query2.toSql )
	end
end