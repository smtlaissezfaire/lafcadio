require 'lafcadio/domain/ObjectType'
require 'lafcadio/test/LafcadioTestCase'
require 'test/mock/domain/User'
require 'test/mock/domain/LineItem'
require 'test/mock/domain'

class TestObjectType < LafcadioTestCase
	def testTableName
		assert_equal( "users", ObjectType.getObjectType(User).tableName )
		assert_equal( "lineItems",
		              ObjectType.getObjectType(Domain::LineItem).tableName )
	end

	def testEnglishName
		assert_equal( "line item",
		              ObjectType.getObjectType(Domain::LineItem).englishName )
		assert_equal( "user", ObjectType.getObjectType(User).englishName )
	end
	
	def testHandlesClassWithoutXml
		ot = ObjectType.getObjectType( NoXml )
		assert_equal( 'objId', ot.sqlPrimaryKeyName )
		assert_equal( 'noXmls', ot.tableName )
	end
end
