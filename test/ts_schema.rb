require 'lafcadio/schema'
require '../test/mock_domain'
require '../test/test_case'

class TestCreateTableStatement < LafcadioTestCase
	def test_to_sql
		statement = CreateTableStatement.new( Client )
		sql = statement.to_sql
		assert_no_match( /varchar\(255\),/, sql )
		assert_match( /standard_rate float/, sql )
		assert_match( /notes blob/, sql )
	end
end
