require 'lafcadio/test'
require '../test/mock/domain/User'
require '../test/mock/domain/Client'

class TestGMockObjectStore < LafcadioTestCase
	def testObjectsRetrievable
		@mockObjectStore.commit User.getTestUser
		assert_equal 1, @mockObjectStore.get(User, 1).pkId
	end

	def testAddsPkId
		@mockObjectStore.addObject User.getTestUser
		assert_equal 1, @mockObjectStore.get(User, 1).pkId
		@mockObjectStore.addObject Client.new( { 'pkId' => 10,
				'name' => 'client 10' } )
		assert_equal 'client 10', @mockObjectStore.get(Client, 10).name
		@mockObjectStore.addObject Client.new( { 'pkId' => 20,
				'name' => 'client 20' } )
		assert_equal 'client 20', @mockObjectStore.get(Client, 20).name
	end

	def testUpdate
		@mockObjectStore.commit Client.new( { 'pkId' => 100,
				'name' => 'client 100' } )
		assert_equal 'client 100', @mockObjectStore.get(Client, 100).name
		@mockObjectStore.commit Client.new( { 'pkId' => 100,
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
	
	def testRespectsLimit
		10.times { User.new({ 'firstNames' => 'John' }).commit }
		query = Query.new( User, Query::Equals.new( 'firstNames', 'John', User ) )
		query.limit = (1..5)
		assert_equal( 5, @mockObjectStore.getSubset( query ).size )
	end

	def testDontChangeFieldsUntilCommit
		user = User.getTestUser
		user.commit
		user_prime = @mockObjectStore.getUser( 1 )
		assert( user.object_id != user_prime.object_id )
		new_email = "another@email.com"
		user_prime.email = new_email
		assert( new_email != @mockObjectStore.getUser( 1 ).email )
		user_prime.commit
		assert_equal( new_email, @mockObjectStore.getUser( 1 ).email )
	end
end
