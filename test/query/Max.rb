require 'lafcadio/test'
require '../test/mock/domain/Client'
require 'lafcadio/query'

class TestQuery < LafcadioTestCase
	def testToSql
		query = Query::Max.new(Client)
		assert_equal 'select max(pkId) from clients', query.toSql
		query2 = Query::Max.new( Invoice, 'rate' )
		assert_equal( 'select max(rate) from invoices', query2.toSql )
		query3 = Query::Max.new( XmlSku )
		assert_equal( 'select max(some_other_id) from some_other_table',
		              query3.toSql )
	end
end