require 'lafcadio/test/LafcadioTestCase'
require '../test/mock/domain/User'
class TestObjectStoreCache < LafcadioTestCase
	def testFlush
		@cache = ObjectStore::Cache.new( MockDbBridge.new )
		user = User.getTestUser
		@cache.save(user)
		assert_equal 1, @cache.getAll(User).size
		@cache.flush(user)
		assert_equal 0, @cache.getAll(User).size
	end
end