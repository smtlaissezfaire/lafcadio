require 'lafcadio/query'
require 'lafcadio/test'
require '../test/mock/domain/Client'
require '../test/mock/domain/SKU'

class TestMockDBBridge < LafcadioTestCase
  def setup
  	super
		@mockDbBridge = MockDbBridge.new
    @client = Client.new( {"pkId" => 1, "name" => "clientName1"} )
  end

  def testDumpable
		assert_equal MockDbBridge, Marshal.load(Marshal.dump(@mockDbBridge)).class
  end

  def testLastPkIdInserted
		assert_equal nil, @mockDbBridge.last_pk_id_inserted
    client = Client.new( { "name" => "clientName1" } )
    @mockDbBridge.commit client
    assert_equal 1, @mockDbBridge.last_pk_id_inserted
    assert_nil( client.pkId )
		client2 = Client.new({ 'pkId' => 2 })
		@mockDbBridge.commit client2
		assert_equal 2, client2.pkId
		client3 = Client.new({ })
		@mockDbBridge.commit client3
		assert_equal 3, @mockDbBridge.last_pk_id_inserted
    assert_nil( client3.pkId )
  end

	def testGetCollectionByQuery
		@mockDbBridge.commit @client
		client2 = Client.new({ 'pkId' => 2, 'name' => 'client2' })
		@mockDbBridge.commit client2
		query = Query.new Client, 2
		coll = @mockDbBridge.get_collection_by_query(query)
		assert_equal 1, coll.size
		assert_equal client2, coll[0]
	end

	def get_all(object_type)
		query = Query.new object_type
		@mockDbBridge.get_collection_by_query query
	end

	def testGetAll
		@mockDbBridge.commit @client
		assert_equal @client, get_all(Client)[0]
	end

  def test_returnsCollection
    assert_equal(Array, get_all(Client).class)
  end

	def testRetrievalsByType
		assert_equal 0, @mockDbBridge.retrievalsByType[Client]
		get_all Client
		assert_equal 1, @mockDbBridge.retrievalsByType[Client]
		get_all Client
		assert_equal 2, @mockDbBridge.retrievalsByType[Client]
	end

	def get(object_type, pkId)
		query = Query.new object_type, pkId
		@mockDbBridge.get_collection_by_query(query)[0]
	end

	def testUpdate
		client100 = Client.new( { 'pkId' => 100, 'name' => 'client 100' } )
		@mockDbBridge.commit client100
		assert_equal 'client 100', get(Client, 100).name
		client100Prime = Client.new( { 'pkId' => 100, 'name' => 'client 100.1' })
		@mockDbBridge.commit client100Prime
		assert_equal 'client 100.1', get(Client, 100).name
	end

	def testDelete
		@mockDbBridge.commit @client
		client2 = Client.new({ 'pkId' => 2, 'name' => 'client2' })
		@mockDbBridge.commit client2
		assert_equal 2, get_all(Client).size
		@client.delete = true
		@mockDbBridge.commit @client
		assert_equal 1, get_all(Client).size
		query = Query.new Client, 1
		clientPrime = @mockDbBridge.get_collection_by_query(query)[0]
		assert_nil clientPrime
	end
end