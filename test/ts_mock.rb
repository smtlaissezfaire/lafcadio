require 'lafcadio/domain'
require 'lafcadio/query'
require 'lafcadio/test'
require '../test/mock_domain'

class TestMockDbBridge < LafcadioTestCase
  def setup
  	super
		@mockDbBridge = MockDbBridge.new
    @client = Client.new( {"pk_id" => 1, "name" => "clientName1"} )
  end

	def get(object_type, pk_id)
		query = Query.new object_type, pk_id
		@mockDbBridge.select_dobjs(query)[0]
	end

	def get_all(object_type)
		query = Query.new object_type
		@mockDbBridge.select_dobjs query
	end
	
	def test_commit
		bad_client = Client.new( 'pk_id' => '1', 'name' => 'my name' )
		assert_raise( ArgumentError ) { @mockDbBridge.commit( bad_client ) }
	end
	
	def test_delete
		@mockDbBridge.commit @client
		client2 = Client.new({ 'pk_id' => 2, 'name' => 'client2' })
		@mockDbBridge.commit client2
		assert_equal 2, get_all(Client).size
		@client.delete = true
		@mockDbBridge.commit @client
		assert_equal 1, get_all(Client).size
		query = Query.new Client, 1
		clientPrime = @mockDbBridge.select_dobjs(query)[0]
		assert_nil clientPrime
	end

  def test_dumpable
		assert_equal MockDbBridge, Marshal.load(Marshal.dump(@mockDbBridge)).class
  end

	def test_get_all
		@mockDbBridge.commit @client
		assert_equal @client, get_all(Client)[0]
		(2..10).each { |pk_id|
			@mockDbBridge.commit( Client.new( 'pk_id' => pk_id ) )
		}
		all = get_all( Client )
		assert_equal( 10, all.size )
		( 1..10 ).each { |i| assert_equal( i, all[i-1].pk_id ) }
	end

	def test_group_query
		assert_equal(
			[ { :max => nil } ],
			@mockDbBridge.group_query( Query::Max.new( Client ) )
		)
		@mockDbBridge.commit @client
		assert_equal(
			[ { :max => 1 } ], @mockDbBridge.group_query( Query::Max.new( Client ) )
		)
		assert_equal(
			[ { :max => 'clientName1' } ],
			@mockDbBridge.group_query( Query::Max.new( Client, 'name' ) )
		)
	end

  def test_last_pk_id_inserted
		assert_equal nil, @mockDbBridge.last_pk_id_inserted
    client = Client.new( { "name" => "clientName1" } )
    @mockDbBridge.commit client
    assert_equal 1, @mockDbBridge.last_pk_id_inserted
    assert_nil( client.pk_id )
		client2 = Client.new({ 'pk_id' => 2 })
		@mockDbBridge.commit client2
		assert_equal 2, client2.pk_id
		client3 = Client.new({ })
		@mockDbBridge.commit client3
		assert_equal 3, @mockDbBridge.last_pk_id_inserted
    assert_nil( client3.pk_id )
  end
	
	def test_limit
		( 1..5 ).each { |i|
			client = Client.new( 'pk_id' => i, 'name' => "client #{ i }" )
			@mockDbBridge.commit client
		}
		query1 = Query.new( Client )
		query1.limit = 0..2
		coll1 = @mockDbBridge.select_dobjs query1
		assert_equal( 3, coll1.size )
		( 1..3 ).each { |i| assert_equal( i, coll1[i-1].pk_id ) }
		query2 = Query.new( Client )
		query2.limit = 3..4
		coll2 = @mockDbBridge.select_dobjs query2
		assert_equal( 2, coll2.size )
		[ 4, 5 ].each { |i| assert_equal( i, coll2[i-4].pk_id ) }
		query3 = Query.new( Client )
		query3.limit = 3..4
		query3.order_by = 'pk_id'
		query3.order_by_order = Query::DESC
		coll3 = @mockDbBridge.select_dobjs query3
		assert_equal( 2, coll3.size )
		assert_equal( 2, coll3[0].pk_id )
		assert_equal( 1, coll3[1].pk_id )
	end

	def test_order_by
		( 1..10 ).each { |day|
			rate = day < 6 ? 50 : 40
			@mockDbBridge.commit(
				Invoice.new( 'date' => Date.new( 2005, 1, day ), 'rate' => rate )
			)
		}
		query = Query.new( Invoice )
		query.order_by = 'date'
		query.order_by_order = Query::DESC
		query.limit = 0..4
		invoices = @mockDbBridge.select_dobjs query
		assert_equal( 5, invoices.size )
		( 6..10 ).each { |day|
			date = Date.new( 2005, 1, day )
			assert(
				invoices.any? { |inv| inv.date == date },
				"Couldn't find Invoice for #{ date }"
			)
		}
		query2 = Query.new( Invoice )
		query2.order_by = [ :rate, :date ]
		query2.order_by_order = Query::DESC
		invoices2 = @mockDbBridge.select_dobjs query2
		rates_and_days = [
			[ 50, 5 ], [ 50, 4 ], [ 50, 3 ], [ 50, 2 ], [ 50, 1 ], [ 40, 10 ],
		  [ 40, 9 ], [ 40, 8 ], [ 40, 7 ], [ 40, 6 ]
		]
		rates_and_days.each_with_index do |rate_and_day, i|
			rate, day = *rate_and_day
			invoice = invoices2[i]
			assert_equal( rate, invoice.rate )
			assert_equal( Date.new( 2005, 1, day ), invoice.date )
		end
	end

  def test_returns_collection
    assert_equal(Array, get_all(Client).class)
  end
	
	def test_select_dobjs
		@mockDbBridge.commit @client
		client2 = Client.new({ 'pk_id' => 2, 'name' => 'client2' })
		@mockDbBridge.commit client2
		query = Query.new Client, 2
		coll = @mockDbBridge.select_dobjs(query)
		assert_equal 1, coll.size
		assert_equal client2, coll[0]
	end

	def test_set_next_pk_id
		client = Client.new( 'name' => 'client 1' )
		2.times do
			assert_equal( 1, @mockDbBridge.pre_commit_pk_id( client ) )
		end
		@mockDbBridge.commit client
		client.pk_id = 1
		client3 = Client.new( 'name' => 'client 3' )
		@mockDbBridge.set_next_pk_id( Client, 3 )
		assert_equal( 3, @mockDbBridge.pre_commit_pk_id( client3 ) )
		@mockDbBridge.set_next_pk_id( Client, 3 )
		@mockDbBridge.commit client3
		client3.pk_id = 3
		client4 = Client.new( 'name' => 'client 4' )
		assert_equal( 4, @mockDbBridge.pre_commit_pk_id( client4 ) )
	end
	
	def test_update
		client100 = Client.new( { 'pk_id' => 100, 'name' => 'client 100' } )
		@mockDbBridge.commit client100
		assert_equal 'client 100', get(Client, 100).name
		client100Prime = Client.new( { 'pk_id' => 100, 'name' => 'client 100.1' })
		@mockDbBridge.commit client100Prime
		assert_equal 'client 100.1', get(Client, 100).name
	end
end

class TestMockObjectStore < LafcadioTestCase
	def testAddsPkId
		@mockObjectStore.commit User.uncommitted_mock
		assert_equal 1, @mockObjectStore.get(User, 1).pk_id
		@mockObjectStore.commit Client.new( { 'pk_id' => 10,
				'name' => 'client 10' } )
		assert_equal 'client 10', @mockObjectStore.get(Client, 10).name
		@mockObjectStore.commit Client.new( { 'pk_id' => 20,
				'name' => 'client 20' } )
		assert_equal 'client 20', @mockObjectStore.get(Client, 20).name
	end

	def testDelete
		user = User.uncommitted_mock
		@mockObjectStore.commit user
		assert_equal 1, @mockObjectStore.get_all(User).size
		user.delete = true
		@mockObjectStore.commit user
		assert_equal 0, @mockObjectStore.get_all(User).size
	end

	def testDontChangeFieldsUntilCommit
		user = User.uncommitted_mock
		user.commit
		user_prime = @mockObjectStore.get_user( 1 )
		assert( user.object_id != user_prime.object_id )
		new_email = "another@email.com"
		user_prime.email = new_email
		assert( new_email != @mockObjectStore.get_user( 1 ).email )
		user_prime.commit
		assert_equal( new_email, @mockObjectStore.get_user( 1 ).email )
	end

	def testObjectsRetrievable
		@mockObjectStore.commit User.uncommitted_mock
		assert_equal 1, @mockObjectStore.get(User, 1).pk_id
	end

	def test_order_by
		client1 = Client.new( 'pk_id' => 1, 'name' => 'zzz' )
		client1.commit
		client2 = Client.new( 'pk_id' => 2, 'name' => 'aaa' )
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

	def testRespectsLimit
		10.times { User.new({ 'firstNames' => 'John' }).commit }
		query = Query.new( User, Query::Equals.new( 'firstNames', 'John', User ) )
		query.limit = (1..5)
		assert_equal( 5, @mockObjectStore.get_subset( query ).size )
	end

	def testThrowsDomainObjectNotFoundError
		begin
			@mockObjectStore.get(User, 199)
			fail 'Should throw DomainObjectNotFoundError'
		rescue DomainObjectNotFoundError
			# ok
		end
	end

	def testUpdate
		@mockObjectStore.commit Client.new( { 'pk_id' => 100,
				'name' => 'client 100' } )
		assert_equal 'client 100', @mockObjectStore.get(Client, 100).name
		@mockObjectStore.commit Client.new( { 'pk_id' => 100,
				'name' => 'client 100.1' } )
		assert_equal 'client 100.1', @mockObjectStore.get(Client, 100).name
	end
end


