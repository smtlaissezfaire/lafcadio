require 'lafcadio/test/LafcadioTestCase'
require '../test/mock/domain/User'

class TestObjectStoreCache < LafcadioTestCase
	def setup
		super
		@cache = ObjectStore::Cache.new( MockDbBridge.new )
	end

	def test_clones
		user = User.getTestUser
		user.pkId = 1
		@cache.save( user )
		assert( user.object_id != @cache.get( User, 1 ).object_id )
		@cache.getAll( User ).each { |a_user|
			assert( user.object_id != a_user.object_id )
		}
	end
	
	def test_dumpable
		cache_prime = Marshal.load( Marshal.dump( @cache ) )
		assert_equal( ObjectStore::Cache, cache_prime.class )
	end

	def testFlush
		user = User.getTestUser
		@cache.save(user)
		assert_equal 1, @cache.getAll(User).size
		@cache.flush(user)
		assert_equal 0, @cache.getAll(User).size
	end
end