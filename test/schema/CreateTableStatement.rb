require 'lafcadio/schema'
require 'lafcadio/test'
require '../test/mock/domain/Client'

class TestCreateTableStatement < LafcadioTestCase
	def test_toSql
		statement = CreateTableStatement.new( Client )
		sql = statement.toSql
		assert_not_match( /varchar\(255\),/, sql )
		assert_match( /standard_rate float\(10, 2\)/, sql )
		assert_match( /notes blob/, sql )
	end
end