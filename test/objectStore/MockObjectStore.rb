require 'lafcadio/test/LafcadioTestCase'
require 'test/mock/domain/User'
require 'test/mock/domain/Client'

class TestGMockObjectStore < LafcadioTestCase
	def testObjectsRetrievable
		@mockObjectStore.commit User.getTestUser
		assert_equal 1, @mockObjectStore.get(User, 1).objId
	end

	def testAddsObjId
		@mockObjectStore.addObject User.getTestUser
		assert_equal 1, @mockObjectStore.get(User, 1).objId
		@mockObjectStore.addObject Client.new( { 'objId' => 10,
				'name' => 'client 10' } )
		assert_equal 'client 10', @mockObjectStore.get(Client, 10).name
		@mockObjectStore.addObject Client.new( { 'objId' => 20,
				'name' => 'client 20' } )
		assert_equal 'client 20', @mockObjectStore.get(Client, 20).name
	end

	def testUpdate
		@mockObjectStore.commit Client.new( { 'objId' => 100,
				'name' => 'client 100' } )
		assert_equal 'client 100', @mockObjectStore.get(Client, 100).name
		@mockObjectStore.commit Client.new( { 'objId' => 100,
				'name' => 'client 100.1' } )
		assert_equal 'client 100.1', @mockObjectStore.get(Client, 100).name
	end

	def testThrowsDomainObjectNotFoundError
		begin
			@mockObjectStore.get(User, 199)
			fail 'Should throw DomainObjectNotFoundError'
		rescue DomainObjectNotFoundError
			# ok
		end
	end
	
	def testDelete
		user = User.getTestUser
		@mockObjectStore.commit user
		assert_equal 1, @mockObjectStore.getAll(User).size
		user.delete = true
		@mockObjectStore.commit user
		assert_equal 0, @mockObjectStore.getAll(User).size
	end
end
