require 'lafcadio/test'
require '../test/mock/domain/Client'
require 'lafcadio/query'

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