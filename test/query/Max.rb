require 'lafcadio/test/LafcadioTestCase'
require 'test/mock/domain/Client'

class TestQuery < LafcadioTestCase
	def testToSql
		query = Query::Max.new(Client)
		assert_equal 'select max(objId) from clients', query.toSql
	end
end