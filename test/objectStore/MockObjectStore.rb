require 'lafcadio/test'
require '../test/mock/domain/User'
require '../test/mock/domain/Client'

class TestGMockObjectStore < LafcadioTestCase
	def testObjectsRetrievable
		@mockObjectStore.commit User.getTestUser
		assert_equal 1, @mockObjectStore.get(User, 1).pk_id
	end

	def testAddsPkId
		@mockObjectStore.commit User.getTestUser
		assert_equal 1, @mockObjectStore.get(User, 1).pk_id
		@mockObjectStore.commit Client.new( { 'pk_id' => 10,
				'name' => 'client 10' } )
		assert_equal 'client 10', @mockObjectStore.get(Client, 10).name
		@mockObjectStore.commit Client.new( { 'pk_id' => 20,
				'name' => 'client 20' } )
		assert_equal 'client 20', @mockObjectStore.get(Client, 20).name
	end

	def testUpdate
		@mockObjectStore.commit Client.new( { 'pk_id' => 100,
				'name' => 'client 100' } )
		assert_equal 'client 100', @mockObjectStore.get(Client, 100).name
		@mockObjectStore.commit Client.new( { 'pk_id' => 100,
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
		assert_equal 1, @mockObjectStore.get_all(User).size
		user.delete = true
		@mockObjectStore.commit user
		assert_equal 0, @mockObjectStore.get_all(User).size
	end
	
	def testRespectsLimit
		10.times { User.new({ 'firstNames' => 'John' }).commit }
		query = Query.new( User, Query::Equals.new( 'firstNames', 'John', User ) )
		query.limit = (1..5)
		assert_equal( 5, @mockObjectStore.get_subset( query ).size )
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
	
	def test_order_by
		client1 = Client.new( 'pkId' => 1, 'name' => 'zzz' )
		client1.commit
		client2 = Client.new( 'pkId' => 2, 'name' => 'aaa' )
		client2.commit
		query = Query.new Client
		query.order_by = 'name'
		clients = @mockObjectStore.get_subset( query )
		assert_equal( 2, clients.size )
		assert_equal( 'aaa', clients.first.name )
		assert_equal( 'zzz', clients.last.name )
		query2 = Query.new Client
		query2.order_by = 'name'
		query2.order_by_order = Query::DESC
		clients2 = @mockObjectStore.get_subset( query2 )
		assert_equal( 2, clients2.size )
		assert_equal( 'zzz', clients2.first.name )
		assert_equal( 'aaa', clients2.last.name )
	end
end
