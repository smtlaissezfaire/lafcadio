require 'lafcadio/domain/ObjectType'
require 'lafcadio/test/LafcadioTestCase'
require 'test/mock/domain/User'
require 'test/mock/domain/LineItem'

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
end
