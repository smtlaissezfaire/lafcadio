require 'lafcadio/domain/ObjectType'
require 'lafcadio/test/LafcadioTestCase'
require 'test/mock/domain/User'
require 'test/mock/domain/LineItem'

class TestObjectType < LafcadioTestCase
	def testTableName
		assert_equal "users", ObjectType.new(User).tableName
		assert_equal "lineItems", ObjectType.new(Domain::LineItem).tableName
	end

	def testEnglishName
		assert_equal "line item", ObjectType.new(Domain::LineItem).englishName
		assert_equal "user", ObjectType.new(User).englishName
	end
end
