require 'lafcadio/domain'
require 'lafcadio/query'
require 'lafcadio/test'
require '../test/mock/domain'

class TestMockDBBridge < LafcadioTestCase
  def setup
  	super
		@mockDbBridge = MockDbBridge.new
    @client = Client.new( {"pk_id" => 1, "name" => "clientName1"} )
  end

	def get(object_type, pk_id)
		query = Query.new object_type, pk_id
		@mockDbBridge.get_collection_by_query(query)[0]
	end

	def get_all(object_type)
		query = Query.new object_type
		@mockDbBridge.get_collection_by_query query
	end
	
	def test_commit
		bad_client = Client.new( 'pk_id' => '1', 'name' => 'my name' )
		assert_raise( ArgumentError ) { @mockDbBridge.commit( bad_client ) }
	end

	def testDelete
		@mockDbBridge.commit @client
		client2 = Client.new({ 'pk_id' => 2, 'name' => 'client2' })
		@mockDbBridge.commit client2
		assert_equal 2, get_all(Client).size
		@client.delete = true
		@mockDbBridge.commit @client
		assert_equal 1, get_all(Client).size
		query = Query.new Client, 1
		clientPrime = @mockDbBridge.get_collection_by_query(query)[0]
		assert_nil clientPrime
	end

  def testDumpable
		assert_equal MockDbBridge, Marshal.load(Marshal.dump(@mockDbBridge)).class
  end

	def testGetAll
		@mockDbBridge.commit @client
		assert_equal @client, get_all(Client)[0]
		(2..10).each { |pk_id|
			@mockDbBridge.commit( Client.new( 'pk_id' => pk_id ) )
		}
		all = get_all( Client )
		assert_equal( 10, all.size )
		( 1..10 ).each { |i| assert_equal( i, all[i-1].pk_id ) }
	end

	def testGetCollectionByQuery
		@mockDbBridge.commit @client
		client2 = Client.new({ 'pk_id' => 2, 'name' => 'client2' })
		@mockDbBridge.commit client2
		query = Query.new Client, 2
		coll = @mockDbBridge.get_collection_by_query(query)
		assert_equal 1, coll.size
		assert_equal client2, coll[0]
	end

  def testLastPkIdInserted
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
		coll1 = @mockDbBridge.get_collection_by_query query1
		assert_equal( 3, coll1.size )
		( 1..3 ).each { |i| assert_equal( i, coll1[i-1].pk_id ) }
		query2 = Query.new( Client )
		query2.limit = 3..4
		coll2 = @mockDbBridge.get_collection_by_query query2
		assert_equal( 2, coll2.size )
		[ 4, 5 ].each { |i| assert_equal( i, coll2[i-4].pk_id ) }
		query3 = Query.new( Client )
		query3.limit = 3..4
		query3.order_by = 'pk_id'
		query3.order_by_order = Query::DESC
		coll3 = @mockDbBridge.get_collection_by_query query3
		assert_equal( 2, coll3.size )
		assert_equal( 2, coll3[0].pk_id )
		assert_equal( 1, coll3[1].pk_id )
	end

	def test_order_by
		( 1..10 ).each { |day|
			@mockDbBridge.commit Invoice.new( 'date' => Date.new( 2005, 1, day ) )
		}
		query = Query.new( Invoice )
		query.order_by = 'date'
		query.order_by_order = Query::DESC
		query.limit = 0..4
		invoices = @mockDbBridge.get_collection_by_query query
		assert_equal( 5, invoices.size )
		( 6..10 ).each { |day|
			date = Date.new( 2005, 1, day )
			assert(
				invoices.any? { |inv| inv.date == date },
				"Couldn't find Invoice for #{ date }"
			)
		}
	end

	def testRetrievalsByType
		assert_equal 0, @mockDbBridge.retrievals_by_type[Client]
		get_all Client
		assert_equal 1, @mockDbBridge.retrievals_by_type[Client]
		get_all Client
		assert_equal 2, @mockDbBridge.retrievals_by_type[Client]
	end

  def test_returnsCollection
    assert_equal(Array, get_all(Client).class)
  end

	def testUpdate
		client100 = Client.new( { 'pk_id' => 100, 'name' => 'client 100' } )
		@mockDbBridge.commit client100
		assert_equal 'client 100', get(Client, 100).name
		client100Prime = Client.new( { 'pk_id' => 100, 'name' => 'client 100.1' })
		@mockDbBridge.commit client100Prime
		assert_equal 'client 100.1', get(Client, 100).name
	end
end